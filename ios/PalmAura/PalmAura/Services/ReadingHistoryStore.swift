import Foundation

/// File-backed history of every reading the user has completed on this
/// device. Mirrors `PalmPhotoStore` and `ReadingIntentStore`: each entry
/// is one JSON file under `Application Support/Readings/`, keyed by
/// `readingId`. UserDefaults can't hold 20 reading payloads comfortably,
/// and per-reading delete is easier on disk.
///
/// Capacity is bounded by `maxReadings`. Older entries are pruned FIFO
/// (sorted by `createdAt` descending) on every save and at app launch.
/// Pruning cascades the matching palm photo, session intent, and
/// written reflections so we don't leak orphan files.
///
/// Legacy single-slot data from `LastReadingStore` is migrated on first
/// launch via `migrateFromLastReadingIfNeeded()`. The migration is
/// idempotent and removes the legacy UserDefaults key once successful.
enum ReadingHistoryStore {
    /// Maximum number of readings kept on disk.
    static let maxReadings = 20

    /// Legacy UserDefaults key from the removed `LastReadingStore` type.
    /// Read here directly so this store has no dependency on a deleted
    /// type after migration ships.
    private static let legacyKey = "lastReading"

    /// One-shot migration marker. Idempotency is critical — without this
    /// flag a user who deleted their lone migrated reading would get it
    /// re-imported on every launch.
    private static let migrationKey = "palmaura.history.migration.v1"

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Readings", isDirectory: true)
    }

    private static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        // Reading JSON is keepsake data the user can clear in Settings; it
        // doesn't need to survive a device-to-device restore. Excluding
        // from iCloud backup matches our PalmPhotoStore posture.
        values.isExcludedFromBackup = true
        var mutable = directory
        try? mutable.setResourceValues(values)
    }

    private static func url(for readingId: String) -> URL {
        directory.appendingPathComponent(safe(readingId)).appendingPathExtension("json")
    }

    /// Sanitize a reading id into a safe filename. Server-generated IDs
    /// are UUIDs and won't trigger replacement, but defending against
    /// malformed input is cheap.
    private static func safe(_ key: String) -> String {
        key.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
    }

    // MARK: - CRUD

    /// Save a reading and prune to keep the on-disk count bounded.
    /// Returns `false` if the write itself failed (disk full, permission
    /// error, etc.). Prune errors are non-fatal and silently ignored.
    @discardableResult
    static func save(_ reading: PalmReadingResponse) -> Bool {
        do {
            try ensureDirectory()
            let data = try JSONEncoder().encode(reading)
            try data.write(to: url(for: reading.readingId), options: [.atomic])
        } catch {
            return false
        }
        prune()
        return true
    }

    static func load(readingId: String) -> PalmReadingResponse? {
        let path = url(for: readingId)
        guard FileManager.default.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path) else { return nil }
        return try? JSONDecoder().decode(PalmReadingResponse.self, from: data)
    }

    /// All readings sorted newest-first. Sort key is the parsed
    /// `createdAt` ISO8601 string; if a reading's timestamp fails to
    /// parse we fall back to file modification time so the list is still
    /// usefully ordered.
    static func allReadings() -> [PalmReadingResponse] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let entries: [(reading: PalmReadingResponse, sortDate: Date)] = files
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { fileURL in
                guard let data = try? Data(contentsOf: fileURL),
                      let reading = try? JSONDecoder().decode(PalmReadingResponse.self, from: data) else {
                    return nil
                }
                let parsed = ReadingTimestampFormatter.date(from: reading.createdAt)
                let mtime = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate) ?? .distantPast
                return (reading, parsed ?? mtime)
            }

        return entries
            .sorted { $0.sortDate > $1.sortDate }
            .map { $0.reading }
    }

    /// Convenience for HomeView and any other surface that wants "the
    /// latest reading" without enumerating the full history.
    static var mostRecent: PalmReadingResponse? {
        allReadings().first
    }

    /// Delete a single reading and cascade to its photo, session intent, and reflections.
    /// Idempotent: deleting an unknown id is a no-op.
    static func delete(readingId: String) {
        let path = url(for: readingId)
        try? FileManager.default.removeItem(at: path)
        ReadingReflectionStore.delete(forReadingId: readingId)
        ReadingIntentStore.clear(for: readingId)
        PalmPhotoStore.delete(key: readingId)
    }

    /// Wipe all reading-history JSON files. Photos, intents, and reflections are
    /// cleared by the caller (Settings "Clear Reflection History" already
    /// calls `PalmPhotoStore.clearAll()` + `ReadingIntentStore.clearAll()` +
    /// `ReadingReflectionStore.clearAll()` alongside this), so we avoid double-clearing.
    static func clearAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Prune to the `maxReadings` newest entries, cascading photo, intent,
    /// and reflection deletion for everything pruned. Safe to call at any time
    /// — `save(_:)` already calls this, and `PalmAuraApp.init` runs it
    /// at launch as a defensive sweep.
    static func prune() {
        let all = allReadings()
        guard all.count > maxReadings else { return }
        for reading in all.dropFirst(maxReadings) {
            delete(readingId: reading.readingId)
        }
    }

    // MARK: - Migration

    /// One-shot migration from the legacy `LastReadingStore` single-slot
    /// UserDefaults key. Reads the raw key directly (no dependency on the
    /// removed `LastReadingStore` type) and writes it into the new
    /// file-backed store. Marks itself complete via `migrationKey` so
    /// re-running is a no-op and a user who deleted their migrated
    /// reading doesn't get it re-imported on next launch.
    ///
    /// Called once per process from `PalmAuraApp.init`.
    static func migrateFromLastReadingIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }

        guard let data = defaults.data(forKey: legacyKey) else {
            // No legacy data exists, so this one-time migration can be
            // marked complete and skipped on future launches.
            defaults.set(true, forKey: migrationKey)
            return
        }

        guard let reading = try? JSONDecoder().decode(PalmReadingResponse.self, from: data) else {
            // The legacy key is present but not readable as a saved reading.
            // Mark complete so app launch doesn't retry forever, but keep
            // the raw key for any future forensic/manual recovery.
            defaults.set(true, forKey: migrationKey)
            return
        }

        // Don't overwrite a same-id reading that's already in the new
        // store (extremely unlikely, but cheap to guard against). If the
        // new store write fails, do not mark migration complete or delete
        // the only legacy copy — otherwise a transient disk/full permission
        // error would permanently lose the user's latest reading.
        if load(readingId: reading.readingId) == nil, !save(reading) {
            return
        }

        defaults.removeObject(forKey: legacyKey)
        defaults.set(true, forKey: migrationKey)
    }
}
