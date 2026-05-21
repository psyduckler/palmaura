import XCTest
@testable import PalmAura

final class ReadingHistoryStoreTests: XCTestCase {
    /// Legacy UserDefaults key the store migrates from. Mirrors the
    /// private constant in `ReadingHistoryStore` — tests assert against
    /// the real legacy key so a rename of the constant doesn't silently
    /// break the migration test.
    private let legacyKey = "lastReading"
    private let migrationKey = "palmaura.history.migration.v1"

    override func setUp() {
        super.setUp()
        // Wipe every store the history layer touches so each test gets a
        // clean slate. Mirrors the order of operations in setUp for any
        // file-backed store in this codebase.
        ReadingHistoryStore.clearAll()
        PalmPhotoStore.clearAll()
        ReadingIntentStore.clearAll()
        UserDefaults.standard.removeObject(forKey: legacyKey)
        UserDefaults.standard.removeObject(forKey: migrationKey)
    }

    override func tearDown() {
        ReadingHistoryStore.clearAll()
        PalmPhotoStore.clearAll()
        ReadingIntentStore.clearAll()
        UserDefaults.standard.removeObject(forKey: legacyKey)
        UserDefaults.standard.removeObject(forKey: migrationKey)
        super.tearDown()
    }

    // MARK: - CRUD

    func testSaveAndLoadRoundtrip() throws {
        let reading = makeReading(id: "abc", createdAt: "2026-05-19T12:00:00Z")
        XCTAssertTrue(ReadingHistoryStore.save(reading))

        let loaded = try XCTUnwrap(ReadingHistoryStore.load(readingId: "abc"))
        XCTAssertEqual(loaded.readingId, "abc")
        XCTAssertEqual(loaded.title, reading.title)
    }

    func testAllReadingsSortedNewestFirstByCreatedAt() {
        let oldest = makeReading(id: "old", createdAt: "2026-01-01T00:00:00Z")
        let middle = makeReading(id: "mid", createdAt: "2026-03-15T00:00:00Z")
        let newest = makeReading(id: "new", createdAt: "2026-05-19T00:00:00Z")

        // Save in non-chronological insertion order to prove the sort is
        // by createdAt, not insertion order.
        ReadingHistoryStore.save(middle)
        ReadingHistoryStore.save(oldest)
        ReadingHistoryStore.save(newest)

        let ids = ReadingHistoryStore.allReadings().map { $0.readingId }
        XCTAssertEqual(ids, ["new", "mid", "old"])
    }

    func testMostRecentReturnsTopOfAllReadings() {
        ReadingHistoryStore.save(makeReading(id: "a", createdAt: "2026-01-01T00:00:00Z"))
        ReadingHistoryStore.save(makeReading(id: "b", createdAt: "2026-05-01T00:00:00Z"))

        XCTAssertEqual(ReadingHistoryStore.mostRecent?.readingId, "b")
    }

    func testMostRecentIsNilWhenEmpty() {
        XCTAssertNil(ReadingHistoryStore.mostRecent)
    }

    // MARK: - Pruning

    func testPruneTrimsToMaxReadingsKeepingNewest() {
        // Save more than the cap. Use ascending dates so the oldest get
        // pruned, leaving the newest `maxReadings` entries.
        let total = ReadingHistoryStore.maxReadings + 5
        for i in 0..<total {
            // Day 01-25 of May 2026 — sortable lexicographically.
            let createdAt = "2026-05-\(String(format: "%02d", i + 1))T00:00:00Z"
            ReadingHistoryStore.save(makeReading(id: "id-\(i)", createdAt: createdAt))
        }
        // Save() calls prune() inline, but call it again to confirm
        // idempotency (calling on an already-bounded directory is a no-op).
        ReadingHistoryStore.prune()

        let remaining = ReadingHistoryStore.allReadings()
        XCTAssertEqual(remaining.count, ReadingHistoryStore.maxReadings)
        // The newest entry (highest index, day 25) should still be top.
        XCTAssertEqual(remaining.first?.readingId, "id-\(total - 1)")
        // The five oldest (id-0 through id-4) should be gone.
        XCTAssertNil(ReadingHistoryStore.load(readingId: "id-0"))
        XCTAssertNil(ReadingHistoryStore.load(readingId: "id-4"))
        XCTAssertNotNil(ReadingHistoryStore.load(readingId: "id-5"))
    }

    // MARK: - Delete

    func testDeleteRemovesSpecificReading() {
        ReadingHistoryStore.save(makeReading(id: "keep", createdAt: "2026-05-19T00:00:00Z"))
        ReadingHistoryStore.save(makeReading(id: "drop", createdAt: "2026-05-18T00:00:00Z"))

        ReadingHistoryStore.delete(readingId: "drop")

        XCTAssertNil(ReadingHistoryStore.load(readingId: "drop"))
        XCTAssertNotNil(ReadingHistoryStore.load(readingId: "keep"))
    }

    func testDeleteCascadesToPalmPhotoAndIntent() throws {
        let readingId = "cascade-test"
        ReadingHistoryStore.save(makeReading(id: readingId, createdAt: "2026-05-19T00:00:00Z"))

        // Stage a bound photo and a stored intent so we can assert they
        // both get cleaned up by delete().
        let photoBytes = Data([0x01, 0x02, 0x03])
        let pendingKey = PalmPhotoStore.makePendingKey()
        _ = PalmPhotoStore.save(photoBytes, key: pendingKey)
        _ = PalmPhotoStore.bind(pendingKey: pendingKey, to: readingId)
        XCTAssertNotNil(PalmPhotoStore.url(for: readingId))

        let intent = ReadingSessionIntent(focus: "Relationship", question: "test question")
        ReadingIntentStore.save(intent, for: readingId)
        XCTAssertNotNil(ReadingIntentStore.load(for: readingId))

        ReadingHistoryStore.delete(readingId: readingId)

        XCTAssertNil(ReadingHistoryStore.load(readingId: readingId))
        XCTAssertNil(PalmPhotoStore.url(for: readingId))
        XCTAssertNil(ReadingIntentStore.load(for: readingId))
    }

    func testDeleteOfUnknownIdIsNoop() {
        ReadingHistoryStore.save(makeReading(id: "real", createdAt: "2026-05-19T00:00:00Z"))
        ReadingHistoryStore.delete(readingId: "this-id-does-not-exist")
        XCTAssertNotNil(ReadingHistoryStore.load(readingId: "real"))
    }

    func testClearAllWipesEveryReading() {
        ReadingHistoryStore.save(makeReading(id: "a", createdAt: "2026-05-19T00:00:00Z"))
        ReadingHistoryStore.save(makeReading(id: "b", createdAt: "2026-05-18T00:00:00Z"))

        ReadingHistoryStore.clearAll()

        XCTAssertTrue(ReadingHistoryStore.allReadings().isEmpty)
    }

    // MARK: - Migration from legacy LastReadingStore

    func testMigrationImportsLegacyReadingAndClearsLegacyKey() throws {
        let legacy = makeReading(id: "legacy-1", createdAt: "2026-05-10T00:00:00Z")
        let data = try JSONEncoder().encode(legacy)
        UserDefaults.standard.set(data, forKey: legacyKey)

        ReadingHistoryStore.migrateFromLastReadingIfNeeded()

        // Imported into the new store.
        XCTAssertEqual(ReadingHistoryStore.allReadings().map { $0.readingId }, ["legacy-1"])
        // Migration marker set so re-runs are no-ops.
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationKey))
        // Legacy key cleaned up so storage isn't duplicated.
        XCTAssertNil(UserDefaults.standard.data(forKey: legacyKey))
    }

    func testMigrationIsIdempotent() throws {
        let legacy = makeReading(id: "legacy-2", createdAt: "2026-05-10T00:00:00Z")
        let data = try JSONEncoder().encode(legacy)
        UserDefaults.standard.set(data, forKey: legacyKey)
        ReadingHistoryStore.migrateFromLastReadingIfNeeded()

        // Simulate a user who deleted their migrated reading.
        ReadingHistoryStore.delete(readingId: "legacy-2")
        XCTAssertTrue(ReadingHistoryStore.allReadings().isEmpty)

        // Re-running migration must not re-import the deleted reading.
        ReadingHistoryStore.migrateFromLastReadingIfNeeded()
        XCTAssertTrue(ReadingHistoryStore.allReadings().isEmpty)
    }

    func testMigrationWithNoLegacyDataIsNoop() {
        XCTAssertNil(UserDefaults.standard.data(forKey: legacyKey))

        ReadingHistoryStore.migrateFromLastReadingIfNeeded()

        XCTAssertTrue(ReadingHistoryStore.allReadings().isEmpty)
        // Marker still set so we don't keep checking on subsequent launches.
        XCTAssertTrue(UserDefaults.standard.bool(forKey: migrationKey))
    }

    // MARK: - Helpers

    private func makeReading(id: String, createdAt: String) -> PalmReadingResponse {
        PalmReadingResponse(
            status: .ok,
            readingId: id,
            title: "Title \(id)",
            oneLineSummary: "Summary \(id)",
            auraColor: .violet,
            archetype: "Archetype \(id)",
            inferredScannedHand: nil,
            report: ReadingReport(
                heartLine: "",
                headLine: "",
                lifeLine: "",
                fateLine: "",
                currentSeason: "",
                guidance: "",
                ritual: ""
            ),
            rejectionMessage: nil,
            nextReadingHook: nil,
            entertainmentDisclaimer: "For entertainment only",
            createdAt: createdAt
        )
    }
}
