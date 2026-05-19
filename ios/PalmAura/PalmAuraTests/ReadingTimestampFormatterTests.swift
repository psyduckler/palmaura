import XCTest
@testable import PalmAura

final class ReadingTimestampFormatterTests: XCTestCase {
    func testRomanDateParsesISO8601FractionalSeconds() throws {
        let value = ReadingTimestampFormatter.romanDate(from: "2026-05-12T00:00:00.000Z")
        XCTAssertEqual(value, "12 May · MMXXVI")
    }

    func testRomanDateParsesISO8601WithoutFractionalSeconds() throws {
        let value = ReadingTimestampFormatter.romanDate(from: "2026-05-12T00:00:00Z")
        XCTAssertEqual(value, "12 May · MMXXVI")
    }
}
