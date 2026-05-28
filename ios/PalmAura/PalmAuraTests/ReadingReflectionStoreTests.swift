import XCTest
@testable import PalmAura

final class ReadingReflectionStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ReadingHistoryStore.clearAll()
        ReadingReflectionStore.clearAll()
        PalmPhotoStore.clearAll()
        ReadingIntentStore.clearAll()
    }

    override func tearDown() {
        ReadingHistoryStore.clearAll()
        ReadingReflectionStore.clearAll()
        PalmPhotoStore.clearAll()
        ReadingIntentStore.clearAll()
        super.tearDown()
    }

    func testUpsertAndLoadRoundtrip() {
        let saved = ReadingReflectionStore.upsert(
            readingId: "reading-1",
            prompt: .feelsTrueToday,
            response: "  The patience line felt true.  "
        )

        let loaded = ReadingReflectionStore.load(forReadingId: "reading-1")

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first, saved)
        XCTAssertEqual(loaded.first?.readingId, "reading-1")
        XCTAssertEqual(loaded.first?.promptKey, ReflectionPrompt.feelsTrueToday.rawValue)
        XCTAssertEqual(loaded.first?.response, "The patience line felt true.")
    }

    func testUpsertSamePromptPreservesIdAndCreatedAt() throws {
        let first = ReadingReflectionStore.upsert(
            readingId: "reading-1",
            prompt: .readyToLetGo,
            response: "Waiting for permission."
        )

        Thread.sleep(forTimeInterval: 0.02)

        let second = ReadingReflectionStore.upsert(
            readingId: "reading-1",
            prompt: .readyToLetGo,
            response: "Waiting for perfect timing."
        )

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.createdAt, first.createdAt)
        XCTAssertGreaterThan(second.updatedAt, first.updatedAt)
        XCTAssertEqual(second.response, "Waiting for perfect timing.")
        XCTAssertEqual(ReadingReflectionStore.load(forReadingId: "reading-1").count, 1)
    }

    func testMultiplePromptsPerReadingCoexist() {
        ReadingReflectionStore.upsert(readingId: "reading-1", prompt: .feelsTrueToday, response: "One")
        ReadingReflectionStore.upsert(readingId: "reading-1", prompt: .readyToLetGo, response: "Two")
        ReadingReflectionStore.upsert(readingId: "reading-1", prompt: .smallAction, response: "Three")

        let loaded = ReadingReflectionStore.load(forReadingId: "reading-1")
        let keys = Set(loaded.map(\.promptKey))

        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(keys, Set(ReflectionPrompt.allCases.map(\.rawValue)))
    }

    func testDeleteForReadingIdRemovesOnlyThatReading() {
        ReadingReflectionStore.upsert(readingId: "keep", prompt: .feelsTrueToday, response: "Keep me")
        ReadingReflectionStore.upsert(readingId: "drop", prompt: .feelsTrueToday, response: "Drop me")

        ReadingReflectionStore.delete(forReadingId: "drop")

        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "drop"), 0)
        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "keep"), 1)
    }

    func testClearAllRemovesAllReflectionFiles() {
        ReadingReflectionStore.upsert(readingId: "a", prompt: .feelsTrueToday, response: "A")
        ReadingReflectionStore.upsert(readingId: "b", prompt: .smallAction, response: "B")

        ReadingReflectionStore.clearAll()

        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "a"), 0)
        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "b"), 0)
    }

    func testEmptyResponseDeletesPromptAndCountIgnoresIt() {
        ReadingReflectionStore.upsert(readingId: "reading-1", prompt: .smallAction, response: "Take a walk")
        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "reading-1"), 1)

        ReadingReflectionStore.upsert(readingId: "reading-1", prompt: .smallAction, response: "   \n  ")

        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "reading-1"), 0)
        XCTAssertTrue(ReadingReflectionStore.load(forReadingId: "reading-1").isEmpty)
    }

    func testReadingHistoryDeleteCascadesToReflections() {
        ReadingHistoryStore.save(makeReading(id: "cascade", createdAt: "2026-05-28T12:00:00Z"))
        ReadingReflectionStore.upsert(readingId: "cascade", prompt: .feelsTrueToday, response: "This one")
        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "cascade"), 1)

        ReadingHistoryStore.delete(readingId: "cascade")

        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "cascade"), 0)
    }

    func testReadingHistoryPruneCascadesToReflections() {
        let total = ReadingHistoryStore.maxReadings + 2
        for index in 0..<total {
            let createdAt = "2026-05-\(String(format: "%02d", index + 1))T00:00:00Z"
            let id = "reading-\(index)"
            ReadingHistoryStore.save(makeReading(id: id, createdAt: createdAt))
            ReadingReflectionStore.upsert(readingId: id, prompt: .feelsTrueToday, response: "Reflection \(index)")
        }

        ReadingHistoryStore.prune()

        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "reading-0"), 0)
        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "reading-1"), 0)
        XCTAssertEqual(ReadingReflectionStore.count(forReadingId: "reading-\(total - 1)"), 1)
    }

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
                heartLine: "Heart",
                headLine: "Head",
                lifeLine: "Life",
                fateLine: "Fate",
                currentSeason: "Season",
                guidance: "Guidance",
                ritual: "Ritual"
            ),
            rejectionMessage: nil,
            nextReadingHook: nil,
            entertainmentDisclaimer: BrandConfig.entertainmentDisclaimer,
            createdAt: createdAt
        )
    }
}
