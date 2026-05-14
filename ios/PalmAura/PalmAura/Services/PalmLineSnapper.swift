import CoreGraphics
import UIKit

struct PalmLineSnapper {
    var searchRadiusPixels: Int = 14
    var contrastWeight: Double = 0.35

    func snap(_ lineSet: PalmLineSet, to image: UIImage?) -> PalmLineSet {
        guard let image, let sampler = LuminanceSampler(image: image) else { return lineSet }
        return PalmLineSet(
            heart: snap(lineSet.heart, sampler: sampler),
            head: snap(lineSet.head, sampler: sampler),
            life: snap(lineSet.life, sampler: sampler),
            fate: snap(lineSet.fate, sampler: sampler),
            source: lineSet.source,
            confidence: lineSet.confidence
        )
    }

    private func snap(_ path: PalmLinePath, sampler: LuminanceSampler) -> PalmLinePath {
        guard path.points.count > 1 else { return path }
        let snapped = path.points.enumerated().map { index, point in
            snap(point: point, at: index, in: path.points, sampler: sampler)
        }
        return PalmLinePath(points: snapped, midpoint: midpoint(of: snapped), confidence: path.confidence)
    }

    private func snap(point normalizedPoint: CGPoint, at index: Int, in points: [CGPoint], sampler: LuminanceSampler) -> CGPoint {
        let point = CGPoint(x: normalizedPoint.x * CGFloat(sampler.width - 1), y: normalizedPoint.y * CGFloat(sampler.height - 1))
        let tangent = tangentVector(at: index, in: points, sampler: sampler)
        let normal = CGPoint(x: -tangent.y, y: tangent.x)

        var bestPoint = point
        var bestScore = score(at: point, sampler: sampler)
        for offset in -searchRadiusPixels...searchRadiusPixels where offset != 0 {
            let candidate = CGPoint(x: point.x + normal.x * CGFloat(offset), y: point.y + normal.y * CGFloat(offset))
            guard sampler.contains(candidate) else { continue }
            let candidateScore = score(at: candidate, sampler: sampler) - Double(abs(offset)) * 0.002
            if candidateScore > bestScore {
                bestScore = candidateScore
                bestPoint = candidate
            }
        }

        return CGPoint(
            x: min(1, max(0, bestPoint.x / CGFloat(sampler.width - 1))),
            y: min(1, max(0, bestPoint.y / CGFloat(sampler.height - 1)))
        )
    }

    private func tangentVector(at index: Int, in points: [CGPoint], sampler: LuminanceSampler) -> CGPoint {
        let previous = points[max(0, index - 1)]
        let next = points[min(points.count - 1, index + 1)]
        let dx = (next.x - previous.x) * CGFloat(sampler.width)
        let dy = (next.y - previous.y) * CGFloat(sampler.height)
        let length = max(0.0001, sqrt(dx * dx + dy * dy))
        return CGPoint(x: dx / length, y: dy / length)
    }

    private func score(at point: CGPoint, sampler: LuminanceSampler) -> Double {
        let center = sampler.luminance(at: point)
        let neighbors = [
            sampler.luminance(x: Int(point.x) - 2, y: Int(point.y)),
            sampler.luminance(x: Int(point.x) + 2, y: Int(point.y)),
            sampler.luminance(x: Int(point.x), y: Int(point.y) - 2),
            sampler.luminance(x: Int(point.x), y: Int(point.y) + 2)
        ].reduce(0, +) / 4.0
        let darkness = 1.0 - center
        let localContrast = max(0, neighbors - center)
        return darkness + localContrast * contrastWeight
    }

    private func midpoint(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let middle = points.count / 2
        if points.count.isMultiple(of: 2) {
            let a = points[middle - 1]
            let b = points[middle]
            return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        }
        return points[middle]
    }
}

private final class LuminanceSampler {
    let width: Int
    let height: Int
    private let pixels: [UInt8]

    init?(image: UIImage) {
        guard let cgImage = image.cgImage else { return nil }
        width = cgImage.width
        height = cgImage.height
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &rgba,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var luminance = [UInt8](repeating: 0, count: width * height)
        for index in 0..<(width * height) {
            let r = Double(rgba[index * 4])
            let g = Double(rgba[index * 4 + 1])
            let b = Double(rgba[index * 4 + 2])
            luminance[index] = UInt8(min(255, max(0, 0.2126 * r + 0.7152 * g + 0.0722 * b)))
        }
        pixels = luminance
    }

    func contains(_ point: CGPoint) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < CGFloat(width) && point.y < CGFloat(height)
    }

    func luminance(at point: CGPoint) -> Double {
        luminance(x: Int(round(point.x)), y: Int(round(point.y)))
    }

    func luminance(x: Int, y: Int) -> Double {
        let clampedX = min(width - 1, max(0, x))
        let clampedY = min(height - 1, max(0, y))
        return Double(pixels[clampedY * width + clampedX]) / 255.0
    }
}
