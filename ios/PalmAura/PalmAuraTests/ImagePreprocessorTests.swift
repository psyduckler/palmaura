import XCTest
@testable import PalmAura

final class ImagePreprocessorTests: XCTestCase {
    func testPreprocessorProducesJpegData() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1400, height: 1000))
        let image = renderer.image { ctx in
            UIColor.purple.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1400, height: 1000))
        }
        let data = try XCTUnwrap(ImagePreprocessor.jpegDataForUpload(from: image))
        XCTAssertLessThan(data.count, 900_000)
    }
}
