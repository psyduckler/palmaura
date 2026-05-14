import CoreGraphics
import Foundation

struct PalmLinePath: Codable, Equatable {
    let points: [CGPoint]
    let midpoint: CGPoint
    let confidence: Double

    init(points: [CGPoint], midpoint: CGPoint, confidence: Double) {
        self.points = points
        self.midpoint = midpoint
        self.confidence = confidence
    }

    enum CodingKeys: String, CodingKey { case points, midpoint, confidence }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode([NormalizedPoint].self, forKey: .points).map(\.cgPoint)
        midpoint = try container.decode(NormalizedPoint.self, forKey: .midpoint).cgPoint
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.7
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points.map(NormalizedPoint.init), forKey: .points)
        try container.encode(NormalizedPoint(midpoint), forKey: .midpoint)
        try container.encode(confidence, forKey: .confidence)
    }
}

struct PalmLineSet: Codable, Equatable {
    enum Source: String, Codable { case aiDetected = "ai_detected", fallback }

    let heart: PalmLinePath
    let head: PalmLinePath
    let life: PalmLinePath
    let fate: PalmLinePath
    let source: Source
    let confidence: Double

    func path(for line: PalmLine) -> PalmLinePath {
        switch line {
        case .heart: return heart
        case .head: return head
        case .life: return life
        case .fate: return fate
        }
    }

    var allPointsAreNormalized: Bool {
        PalmLine.allCases.allSatisfy { line in
            let path = path(for: line)
            return (path.points + [path.midpoint]).allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) }
        }
    }

    static let fallback = PalmLineSet(
        heart: PalmLinePath(points: [CGPoint(x: 0.18, y: 0.38), CGPoint(x: 0.34, y: 0.35), CGPoint(x: 0.55, y: 0.34), CGPoint(x: 0.76, y: 0.37)], midpoint: CGPoint(x: 0.50, y: 0.36), confidence: 0.35),
        head: PalmLinePath(points: [CGPoint(x: 0.22, y: 0.51), CGPoint(x: 0.39, y: 0.48), CGPoint(x: 0.59, y: 0.49), CGPoint(x: 0.78, y: 0.54)], midpoint: CGPoint(x: 0.50, y: 0.50), confidence: 0.35),
        life: PalmLinePath(points: [CGPoint(x: 0.36, y: 0.38), CGPoint(x: 0.27, y: 0.51), CGPoint(x: 0.28, y: 0.70), CGPoint(x: 0.40, y: 0.87)], midpoint: CGPoint(x: 0.31, y: 0.63), confidence: 0.35),
        fate: PalmLinePath(points: [CGPoint(x: 0.52, y: 0.88), CGPoint(x: 0.52, y: 0.70), CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.49, y: 0.40)], midpoint: CGPoint(x: 0.51, y: 0.64), confidence: 0.30),
        source: .fallback,
        confidence: 0.35
    )
}

private struct NormalizedPoint: Codable, Equatable {
    let x: CGFloat
    let y: CGFloat
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    init(_ point: CGPoint) {
        self.x = min(1, max(0, point.x))
        self.y = min(1, max(0, point.y))
    }
}
