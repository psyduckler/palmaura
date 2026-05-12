import XCTest
@testable import PalmAura

final class ContractEncodingTests: XCTestCase {
    func testPalmReadingRequestEncodesBackendKeys() throws {
        let request = PalmReadingRequest(clientRequestId: UUID().uuidString, deviceId: "device", appVersion: "0.1.0", locale: "en_US", imageBase64Jpeg: "abc123", onboarding: .default)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["clientRequestId"])
        XCTAssertNotNil(object["deviceId"])
        XCTAssertNotNil(object["appVersion"])
        XCTAssertNotNil(object["locale"])
        XCTAssertNotNil(object["imageBase64Jpeg"])
        XCTAssertNotNil(object["onboarding"])
    }
}
