import SwiftUI
import XCTest
@testable import PalmAura

@MainActor
final class NavigationCoordinatorTests: XCTestCase {
    func testGoHomeClearsPathAndForcesStackReset() {
        let coordinator = NavigationCoordinator()
        coordinator.path.append("nested-destination")
        let previousResetID = coordinator.stackResetID

        coordinator.goHome()

        XCTAssertEqual(coordinator.path.count, 0)
        XCTAssertNotEqual(coordinator.stackResetID, previousResetID)
    }
}
