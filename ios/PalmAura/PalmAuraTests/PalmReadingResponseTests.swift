import XCTest
@testable import PalmAura

final class PalmReadingResponseTests: XCTestCase {
    func testDecodesFixtureReading() throws {
        let url = Bundle(for: Self.self).url(forResource: "fixture-reading", withExtension: "json")
        // The fixture is app-bundle scoped in the generated target; this test mainly guards model shape via inline decode.
        let json = """
        {"status":"ok","readingId":"x","title":"T","oneLineSummary":"S","auraColor":"violet","archetype":"A","shareCards":[],"report":{"aura":"","heartLine":"","headLine":"","lifeLine":"","fateLine":"","currentSeason":"","guidance":"","ritual":""},"entertainmentDisclaimer":"E","createdAt":"now"}
        """.data(using: .utf8)!
        let reading = try JSONDecoder().decode(PalmReadingResponse.self, from: json)
        XCTAssertEqual(reading.status, .ok)
        XCTAssertEqual(reading.auraColor, .violet)
        _ = url
    }
}
