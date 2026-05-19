import XCTest
@testable import PalmAura

final class ImagePreprocessorTests: XCTestCase {
    func testPreprocessorProducesJpegData() throws {
        let image = makeImage(size: CGSize(width: 1400, height: 1000))
        let data = try XCTUnwrap(ImagePreprocessor.jpegDataForUpload(from: image))
        XCTAssertLessThan(data.count, 900_000)
    }

    func testReviewImageIsBoundedBeforeNavigation() {
        let image = makeImage(size: CGSize(width: 4032, height: 3024))

        let reviewImage = ImagePreprocessor.imageForReview(from: image)

        XCTAssertLessThanOrEqual(max(reviewImage.size.width, reviewImage.size.height), 1024)
        XCTAssertEqual(reviewImage.scale, image.scale)
    }

    private func makeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.purple.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
