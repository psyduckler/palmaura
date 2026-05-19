import XCTest
@testable import PalmAura

final class MysticProfileDescriptorTests: XCTestCase {
    func testProfileDescriptorUsesMysticalContextInsteadOfLiteralGenderEnergy() {
        let personalization = ReadingPersonalization(
            gender: .man,
            handedness: .right,
            birthDate: BirthDateContext(month: 5, day: 2, year: 1990)
        )

        let descriptor = MysticProfileDescriptor.make(from: personalization)

        XCTAssertFalse(descriptor.title.isEmpty)
        XCTAssertEqual(descriptor, MysticProfileDescriptor.make(from: personalization))
        XCTAssertTrue(descriptor.subtitle.contains("Taurus sun"))
        XCTAssertTrue(descriptor.subtitle.contains("solar current"))
        XCTAssertTrue(descriptor.subtitle.contains("right-hand path"))
        XCTAssertFalse(descriptor.subtitle.contains("Man energy"))
    }

    func testEmptyProfileFallsBackWithoutPretendingPersonalization() {
        let descriptor = MysticProfileDescriptor.make(from: ReadingPersonalization())

        XCTAssertEqual(descriptor.title, "Starlit Seeker")
        XCTAssertEqual(descriptor.subtitle, "Profile not set")
    }
}
