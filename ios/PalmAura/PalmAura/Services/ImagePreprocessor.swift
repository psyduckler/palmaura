import UIKit

enum ImagePreprocessor {
    static func jpegDataForUpload(from image: UIImage) -> Data? {
        let first = resized(image, maxLongestEdge: 1024).jpegData(compressionQuality: 0.7)
        if let first, first.count <= 800_000 { return first }
        return resized(image, maxLongestEdge: 768).jpegData(compressionQuality: 0.6)
    }

    private static func resized(_ image: UIImage, maxLongestEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxLongestEdge else { return image }
        let scale = maxLongestEdge / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
