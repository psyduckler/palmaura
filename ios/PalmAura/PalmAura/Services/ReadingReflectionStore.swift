import Foundation

/// File-backed local journal responses for a completed reading.
///
/// Each reading owns one JSON file under Application Support/Reflections.
/// Reflection text is intentionally local-only: it is never sent to the
/// backend and is cleared with reading history.
enum ReadingReflectionStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Reflections", isDirectory: true)
    }

    static func load(forReadingId readingId: String) -> [ReadingReflection] {
        let path = file(for: readingId)
        guard FileManager.default.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path),
              let decoded = try? JSONDecoder().decode([ReadingReflection].self, from: data) else {
            return []
        }
        return decoded.filter { $0.readingId == readingId && !$0.response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    @discardableResult
    static func upsert(readingId: String, prompt: ReflectionPrompt, response: String) -> ReadingReflection {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        var all = load(forReadingId: readingId)

        if trimmed.isEmpty {
            all.removeAll { $0.promptKey == prompt.rawValue }
            write(all, for: readingId)
            return ReadingReflection(readingId: readingId, promptKey: prompt.rawValue, response: "")
        }

        if let index = all.firstIndex(where: { $0.promptKey == prompt.rawValue }) {
            let existing = all[index]
            let updated = ReadingReflection(
                id: existing.id,
                readingId: existing.readingId,
                promptKey: existing.promptKey,
                response: trimmed,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            all[index] = updated
            write(all, for: readingId)
            return updated
        }

        let created = ReadingReflection(readingId: readingId, promptKey: prompt.rawValue, response: trimmed)
        all.append(created)
        write(all, for: readingId)
        return created
    }

    static func delete(forReadingId readingId: String) {
        try? FileManager.default.removeItem(at: file(for: readingId))
    }

    static func clearAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }
        for file in files { try? FileManager.default.removeItem(at: file) }
    }

    static func count(forReadingId readingId: String) -> Int {
        load(forReadingId: readingId).count
    }

    // MARK: - Private

    private static func file(for readingId: String) -> URL {
        directory.appendingPathComponent(safe(readingId)).appendingPathExtension("json")
    }

    private static func write(_ reflections: [ReadingReflection], for readingId: String) {
        if reflections.isEmpty {
            delete(forReadingId: readingId)
            return
        }

        do {
            try ensureDirectory()
            let data = try JSONEncoder().encode(reflections)
            try data.write(to: file(for: readingId), options: [.atomic])
        } catch {
            // Best-effort local journal. If disk writes fail, keep the reading flow alive.
        }
    }

    private static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = directory
        try? mutable.setResourceValues(values)
    }

    private static func safe(_ key: String) -> String {
        key.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
    }
}
