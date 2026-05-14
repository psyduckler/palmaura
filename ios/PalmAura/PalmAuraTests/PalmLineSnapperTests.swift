import XCTest
@testable import PalmAura

final class PalmLineSnapperTests: XCTestCase {
    func testSnapsPointOntoNearbyDarkCrease() throws {
        let image = makeSyntheticPalmImage()
        let roughY: CGFloat = 0.46
        let path = PalmLinePath(
            points: [
                CGPoint(x: 0.20, y: roughY),
                CGPoint(x: 0.35, y: roughY),
                CGPoint(x: 0.50, y: roughY),
                CGPoint(x: 0.65, y: roughY),
                CGPoint(x: 0.80, y: roughY)
            ],
            midpoint: CGPoint(x: 0.50, y: roughY),
            confidence: 0.9
        )
        let set = PalmLineSet(heart: path, head: path, life: path, fate: path, source: .aiDetected, confidence: 0.9)

        let snapped = PalmLineSnapper(searchRadiusPixels: 14).snap(set, to: image)

        let snappedY = snapped.heart.points[2].y
        XCTAssertEqual(snappedY, 0.50, accuracy: 0.025)
        XCTAssertLessThan(abs(snappedY - 0.50), abs(roughY - 0.50))
    }

    private func makeSyntheticPalmImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(white: 0.86, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 3
            path.move(to: CGPoint(x: 10, y: 50))
            path.addLine(to: CGPoint(x: 90, y: 50))
            path.stroke()
        }
    }
}
