import SwiftUI

struct PalmCanvasView: View {
    enum RenderingMode { case preciseLines, softGlow }

    let photoURL: URL?
    let lineSet: PalmLineSet
    let auraColor: AuraColor
    var activeLine: PalmLine?
    var ignitionProgress: CGFloat = 1
    var renderingMode: RenderingMode = .preciseLines
    var onSelectLine: ((PalmLine) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                palmImage
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                Rectangle()
                    .fill(radialGradient.opacity(renderingMode == .softGlow ? 0.32 : 0.18))
                    .blendMode(.screen)

                ForEach(PalmLine.allCases) { line in
                    lineShape(line: line, in: geometry.size)
                        .trim(from: 0, to: trimEnd(for: line))
                        .stroke(style: style(for: line, glow: true))
                        .foregroundStyle(color(for: line).opacity(renderingMode == .softGlow ? 0.35 : 0.58))
                        .blur(radius: renderingMode == .softGlow ? 14 : 9)
                        .blendMode(.screen)

                    lineShape(line: line, in: geometry.size)
                        .trim(from: 0, to: trimEnd(for: line))
                        .stroke(style: style(for: line, glow: false))
                        .foregroundStyle(color(for: line).opacity(opacity(for: line)))
                        .blendMode(.screen)
                }

                ForEach(PalmLine.allCases) { line in
                    let midpoint = denormalize(lineSet.path(for: line).midpoint, in: geometry.size)
                    Circle()
                        .fill(.clear)
                        .contentShape(Circle())
                        .frame(width: 56, height: 56)
                        .position(midpoint)
                        .onTapGesture { onSelectLine?(line) }
                        .accessibilityLabel("Select \(line.title)")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityText)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .onAppear {
            Analytics.shared.track("palm_canvas_rendered", properties: ["source": lineSet.source.rawValue, "confidence": String(format: "%.2f", lineSet.confidence)])
        }
    }

    private var palmImage: some View {
        Group {
            if let photoURL, let image = UIImage(contentsOfFile: photoURL.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            DesignSystem.ColorToken.skyDeep,
                            DesignSystem.ColorToken.skyMulberry.opacity(0.55),
                            DesignSystem.ColorToken.skyDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    PalmAuraMark(style: .capture, size: 120).opacity(0.75)
                }
            }
        }
    }

    private var radialGradient: RadialGradient {
        RadialGradient(colors: [swiftUIColor.opacity(0.9), .clear], center: .center, startRadius: 20, endRadius: 340)
    }

    private var swiftUIColor: Color {
        switch auraColor {
        case .violet: return .purple
        case .gold: return .yellow
        case .fire: return .orange
        case .moon: return .white
        case .water: return .cyan
        case .rose: return .pink
        }
    }

    private func color(for line: PalmLine) -> Color {
        if activeLine == nil || activeLine == line { return swiftUIColor }
        return .white
    }

    private func opacity(for line: PalmLine) -> Double {
        let confidence = max(0.25, min(1, lineSet.path(for: line).confidence))
        if renderingMode == .softGlow { return (activeLine == line ? 0.35 : 0.16) * confidence }
        if activeLine == nil { return 0.92 * confidence }
        return (activeLine == line ? 1 : 0.22) * confidence
    }

    private func style(for line: PalmLine, glow: Bool) -> StrokeStyle {
        if renderingMode == .softGlow {
            return StrokeStyle(lineWidth: glow ? 42 : 1, lineCap: .round, lineJoin: .round)
        }
        let selected = activeLine == nil || activeLine == line
        return StrokeStyle(lineWidth: glow ? (selected ? 18 : 10) : (selected ? 5 : 2.5), lineCap: .round, lineJoin: .round)
    }

    private func trimEnd(for line: PalmLine) -> CGFloat {
        let perLineDelay = CGFloat(PalmLine.allCases.firstIndex(of: line) ?? 0) * 0.08
        return min(1, max(0, (ignitionProgress - perLineDelay) / 0.72))
    }

    private func lineShape(line: PalmLine, in size: CGSize) -> Path {
        let points = lineSet.path(for: line).points.map { denormalize($0, in: size) }
        return Path.smoothed(points: points)
    }

    private func denormalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    private var accessibilityText: String {
        if let activeLine { return "Palm map. \(activeLine.title) selected." }
        return "Palm map with heart, head, life, and fate lines."
    }
}

private extension Path {
    static func smoothed(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
            if index == points.count - 1 { path.addQuadCurve(to: current, control: current) }
        }
        return path
    }
}
