import XCTest
@testable import PalmAura

final class ContractEncodingTests: XCTestCase {
    func testPalmReadingRequestEncodesBackendKeysAndSessionQuestion() throws {
        var personalization = ReadingPersonalization(
            gender: .nonBinary,
            handedness: .ambidextrous,
            birthDate: BirthDateContext(month: 5, day: 13, year: 1990)
        )
        personalization.question = "What should I understand about this relationship?"
        let onboarding = OnboardingAnswers(
            focus: .love,
            lifeSeason: .bigDecision,
            readingStyle: .mysterious,
            personalization: personalization,
            sessionIntent: ReadingSessionIntent(focus: "Relationship", question: personalization.question)
        )
        let request = PalmReadingRequest(clientRequestId: UUID().uuidString, deviceId: "device", appVersion: "0.1.0", locale: "en_US", imageBase64Jpeg: "abc123", onboarding: onboarding)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["clientRequestId"])
        XCTAssertNotNil(object["deviceId"])
        XCTAssertNotNil(object["appVersion"])
        XCTAssertNotNil(object["locale"])
        XCTAssertNotNil(object["imageBase64Jpeg"])
        let onboardingObject = try XCTUnwrap(object["onboarding"] as? [String: Any])
        XCTAssertEqual(onboardingObject["focus"] as? String, "love")
        XCTAssertEqual(onboardingObject["lifeSeason"] as? String, "big_decision")
        XCTAssertEqual(onboardingObject["readingStyle"] as? String, "mysterious")
        XCTAssertNil(onboardingObject["sessionIntent"])
        let profile = try XCTUnwrap(onboardingObject["personalization"] as? [String: Any])
        XCTAssertEqual(profile["gender"] as? String, "non_binary")
        XCTAssertEqual(profile["handedness"] as? String, "ambidextrous")
        XCTAssertEqual(profile["question"] as? String, "What should I understand about this relationship?")
        let birthDate = try XCTUnwrap(profile["birthDate"] as? [String: Any])
        XCTAssertEqual(birthDate["year"] as? Int, 1990)
    }
}
