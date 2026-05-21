import XCTest
@testable import PalmAura

final class InlineMarkdownFormatterTests: XCTestCase {
    func testSingleAsteriskEmphasisBecomesItalicTextWithoutLiteralDelimiters() {
        let attributed = InlineMarkdownFormatter.attributedString(
            from: "Your palm says *wait for the door to open* before moving."
        )

        XCTAssertEqual(
            String(attributed.characters),
            "Your palm says wait for the door to open before moving."
        )
        XCTAssertEqual(emphasizedSegments(in: attributed), ["wait for the door to open"])
    }

    func testLiteralStarsOutsideMarkdownEmphasisArePreserved() {
        let attributed = InlineMarkdownFormatter.attributedString(
            from: "The pattern is 5 * 3, then *move softly*."
        )

        XCTAssertEqual(
            String(attributed.characters),
            "The pattern is 5 * 3, then move softly."
        )
        XCTAssertEqual(emphasizedSegments(in: attributed), ["move softly"])
    }

    func testMalformedMarkdownFallsBackToVisibleText() {
        let attributed = InlineMarkdownFormatter.attributedString(
            from: "Keep the unfinished *marker visible."
        )

        XCTAssertEqual(String(attributed.characters), "Keep the unfinished *marker visible.")
        XCTAssertTrue(emphasizedSegments(in: attributed).isEmpty)
    }

    private func emphasizedSegments(in attributed: AttributedString) -> [String] {
        attributed.runs.compactMap { run in
            guard run.inlinePresentationIntent?.contains(.emphasized) == true else { return nil }
            return String(attributed[run.range].characters)
        }
    }
}
