import XCTest
@testable import PalmAura

final class ContractEncodingTests: XCTestCase {
    func testPalmReadingRequestEncodesBackendKeys() throws {
        let personalization = ReadingPersonalization(
            gender: .nonBinary,
            handedness: .ambidextrous,
            birthDate: BirthDateContext(month: 5, day: 13, year: 1990),
            question: "legacy question should not be sent"
        )
        let onboarding = OnboardingAnswers(focus: .general, lifeSeason: .unknown, readingStyle: .mysterious, personalization: personalization.withoutQuestion)
        let request = PalmReadingRequest(clientRequestId: UUID().uuidString, deviceId: "device", appVersion: "0.1.0", locale: "en_US", imageBase64Jpeg: "abc123", onboarding: onboarding)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["clientRequestId"])
        XCTAssertNotNil(object["deviceId"])
        XCTAssertNotNil(object["appVersion"])
        XCTAssertNotNil(object["locale"])
        XCTAssertNotNil(object["imageBase64Jpeg"])
        let onboardingObject = try XCTUnwrap(object["onboarding"] as? [String: Any])
        let profile = try XCTUnwrap(onboardingObject["personalization"] as? [String: Any])
        XCTAssertEqual(profile["gender"] as? String, "non_binary")
        XCTAssertEqual(profile["handedness"] as? String, "ambidextrous")
        XCTAssertNil(profile["question"])
        let birthDate = try XCTUnwrap(profile["birthDate"] as? [String: Any])
        XCTAssertEqual(birthDate["year"] as? Int, 1990)
    }
}
