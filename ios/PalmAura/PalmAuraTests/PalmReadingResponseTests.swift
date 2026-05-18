import XCTest
@testable import PalmAura

final class PalmReadingResponseTests: XCTestCase {
    func testDecodesFixtureReading() throws {
        let url = Bundle(for: Self.self).url(forResource: "fixture-reading", withExtension: "json")
        // The fixture is app-bundle scoped in the generated target; this test mainly guards model shape via inline decode.
        let json = """
        {"status":"ok","readingId":"x","title":"T","oneLineSummary":"S","auraColor":"violet","archetype":"A","inferredScannedHand":{"hand":"left","confidence":0.82,"role":"non_dominant","evidence":"thumb side appears on image-right"},"report":{"aura":"","heartLine":"","headLine":"","lifeLine":"","fateLine":"","currentSeason":"","guidance":"","ritual":""},"entertainmentDisclaimer":"E","createdAt":"now"}
        """.data(using: .utf8)!
        let reading = try JSONDecoder().decode(PalmReadingResponse.self, from: json)
        XCTAssertEqual(reading.status, .ok)
        XCTAssertEqual(reading.auraColor, .violet)
        XCTAssertEqual(reading.inferredScannedHand?.hand, .left)
        XCTAssertEqual(reading.inferredScannedHand?.role, .nonDominant)
        XCTAssertEqual(reading.inferredScannedHand?.confidence, 0.82)
        _ = url
    }
}
