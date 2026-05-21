import XCTest
import UIKit
@testable import PalmAura

final class ShareReportPayloadTests: XCTestCase {
    func testActivityItemsShareReadingTextInsteadOfStandaloneWebsiteURL() throws {
        let reading = makeReading()
        let items = ShareReportPayload.activityItems(image: UIImage(), reading: reading)

        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0] is UIImage)
        XCTAssertFalse(items.contains { $0 is URL }, "A standalone URL makes many share targets prefer palmaura.app over the reading.")

        let text = try XCTUnwrap(items.compactMap { $0 as? String }.first)
        XCTAssertNotEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), BrandConfig.websiteURL)
        XCTAssertTrue(text.contains("The Ember Thread"))
        XCTAssertTrue(text.contains("A decisive season is opening."))
        XCTAssertTrue(text.contains("Heart line: Your warmth is steady."))
        XCTAssertTrue(text.contains("Guidance: Choose the clean yes."))
        XCTAssertTrue(text.contains(BrandConfig.websiteURL))
    }

    private func makeReading() -> PalmReadingResponse {
        PalmReadingResponse(
            status: .ok,
            readingId: "share-test",
            title: "The Ember Thread",
            oneLineSummary: "A decisive season is opening.",
            auraColor: .fire,
            archetype: "The Builder",
            inferredScannedHand: nil,
            report: ReadingReport(
                heartLine: "Your warmth is steady.",
                headLine: "Your attention sharpens under pressure.",
                lifeLine: "You recover quickly after change.",
                fateLine: "Momentum arrives through one brave commitment.",
                currentSeason: "A threshold month.",
                guidance: "Choose the clean yes.",
                ritual: "Write the decision once and sleep on it."
            ),
            rejectionMessage: nil,
            nextReadingHook: nil,
            entertainmentDisclaimer: "For entertainment only.",
            createdAt: "2026-05-21T13:00:00Z"
        )
    }
}
