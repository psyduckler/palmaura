import SwiftUI

struct PalmAuraMark: View {
    enum Style {
        case capture
        case loading(ignitionProgress: Double = 1)
    }

    var style: Style = .capture
    var size: CGFloat = 96
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignSystem.ColorToken.solarGold.opacity(0.32),
                                DesignSystem.ColorToken.mysticPurple.opacity(0.14),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.05,
                            endRadius: size * 0.68
                        )
                    )
                    .frame(width: size * 1.45, height: size * 1.45)
                    .blur(radius: size * 0.08)
                    .accessibilityHidden(true)
            }

            palmShape
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.86, blue: 0.54), Color(red: 0.94, green: 0.58, blue: 0.84)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(palmShape.stroke(.white.opacity(0.36), lineWidth: max(1.2, size * 0.018)))
                .frame(width: size, height: size)
                .shadow(color: DesignSystem.ColorToken.solarGold.opacity(showGlow ? 0.32 : 0), radius: size * 0.14)

            markCreases
                .trim(from: 0, to: ignitionProgress)
                .stroke(
                    DesignSystem.ColorToken.moonlight.opacity(0.86),
                    style: StrokeStyle(lineWidth: max(1.4, size * 0.022), lineCap: .round, lineJoin: .round)
                )
                .frame(width: size, height: size)
                .shadow(color: DesignSystem.ColorToken.solarGold.opacity(0.9), radius: size * 0.045)
                .accessibilityHidden(true)
        }
        .frame(width: size * 1.5, height: size * 1.5)
        .accessibilityLabel("PalmAura palm mark")
    }

    private var ignitionProgress: Double {
        switch style {
        case .capture:
            return 1
        case let .loading(progress):
            return min(max(progress, 0), 1)
        }
    }

    private var palmShape: some Shape {
        PalmShape()
    }

    private var markCreases: some Shape {
        PalmMarkCreasesShape()
    }
}

private struct PalmShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: 0.34 * w, y: 0.46 * h))
        path.addCurve(to: CGPoint(x: 0.28 * w, y: 0.17 * h), control1: CGPoint(x: 0.31 * w, y: 0.36 * h), control2: CGPoint(x: 0.27 * w, y: 0.24 * h))
        path.addCurve(to: CGPoint(x: 0.40 * w, y: 0.13 * h), control1: CGPoint(x: 0.29 * w, y: 0.10 * h), control2: CGPoint(x: 0.38 * w, y: 0.09 * h))
        path.addCurve(to: CGPoint(x: 0.43 * w, y: 0.38 * h), control1: CGPoint(x: 0.42 * w, y: 0.21 * h), control2: CGPoint(x: 0.42 * w, y: 0.30 * h))
        path.addCurve(to: CGPoint(x: 0.45 * w, y: 0.10 * h), control1: CGPoint(x: 0.43 * w, y: 0.28 * h), control2: CGPoint(x: 0.43 * w, y: 0.17 * h))
        path.addCurve(to: CGPoint(x: 0.58 * w, y: 0.10 * h), control1: CGPoint(x: 0.47 * w, y: 0.04 * h), control2: CGPoint(x: 0.56 * w, y: 0.04 * h))
        path.addCurve(to: CGPoint(x: 0.59 * w, y: 0.39 * h), control1: CGPoint(x: 0.59 * w, y: 0.18 * h), control2: CGPoint(x: 0.59 * w, y: 0.29 * h))
        path.addCurve(to: CGPoint(x: 0.64 * w, y: 0.18 * h), control1: CGPoint(x: 0.60 * w, y: 0.31 * h), control2: CGPoint(x: 0.61 * w, y: 0.24 * h))
        path.addCurve(to: CGPoint(x: 0.76 * w, y: 0.22 * h), control1: CGPoint(x: 0.68 * w, y: 0.12 * h), control2: CGPoint(x: 0.77 * w, y: 0.15 * h))
        path.addCurve(to: CGPoint(x: 0.69 * w, y: 0.48 * h), control1: CGPoint(x: 0.75 * w, y: 0.31 * h), control2: CGPoint(x: 0.72 * w, y: 0.40 * h))
        path.addCurve(to: CGPoint(x: 0.85 * w, y: 0.40 * h), control1: CGPoint(x: 0.75 * w, y: 0.41 * h), control2: CGPoint(x: 0.80 * w, y: 0.38 * h))
        path.addCurve(to: CGPoint(x: 0.87 * w, y: 0.53 * h), control1: CGPoint(x: 0.90 * w, y: 0.42 * h), control2: CGPoint(x: 0.91 * w, y: 0.49 * h))
        path.addCurve(to: CGPoint(x: 0.70 * w, y: 0.70 * h), control1: CGPoint(x: 0.82 * w, y: 0.59 * h), control2: CGPoint(x: 0.75 * w, y: 0.63 * h))
        path.addCurve(to: CGPoint(x: 0.63 * w, y: 0.93 * h), control1: CGPoint(x: 0.66 * w, y: 0.77 * h), control2: CGPoint(x: 0.67 * w, y: 0.87 * h))
        path.addCurve(to: CGPoint(x: 0.39 * w, y: 0.91 * h), control1: CGPoint(x: 0.57 * w, y: 1.00 * h), control2: CGPoint(x: 0.43 * w, y: 0.98 * h))
        path.addCurve(to: CGPoint(x: 0.29 * w, y: 0.66 * h), control1: CGPoint(x: 0.34 * w, y: 0.84 * h), control2: CGPoint(x: 0.33 * w, y: 0.73 * h))
        path.addCurve(to: CGPoint(x: 0.17 * w, y: 0.49 * h), control1: CGPoint(x: 0.25 * w, y: 0.58 * h), control2: CGPoint(x: 0.15 * w, y: 0.57 * h))
        path.addCurve(to: CGPoint(x: 0.30 * w, y: 0.44 * h), control1: CGPoint(x: 0.18 * w, y: 0.42 * h), control2: CGPoint(x: 0.26 * w, y: 0.41 * h))
        path.closeSubpath()
        return path
    }
}

private struct PalmMarkCreasesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: 0.31 * w, y: 0.52 * h))
        path.addCurve(to: CGPoint(x: 0.68 * w, y: 0.47 * h), control1: CGPoint(x: 0.42 * w, y: 0.42 * h), control2: CGPoint(x: 0.55 * w, y: 0.42 * h))

        path.move(to: CGPoint(x: 0.33 * w, y: 0.62 * h))
        path.addCurve(to: CGPoint(x: 0.61 * w, y: 0.72 * h), control1: CGPoint(x: 0.44 * w, y: 0.64 * h), control2: CGPoint(x: 0.51 * w, y: 0.70 * h))

        path.move(to: CGPoint(x: 0.50 * w, y: 0.50 * h))
        path.addCurve(to: CGPoint(x: 0.48 * w, y: 0.84 * h), control1: CGPoint(x: 0.52 * w, y: 0.61 * h), control2: CGPoint(x: 0.49 * w, y: 0.73 * h))

        path.move(to: CGPoint(x: 0.38 * w, y: 0.74 * h))
        path.addCurve(to: CGPoint(x: 0.58 * w, y: 0.57 * h), control1: CGPoint(x: 0.43 * w, y: 0.66 * h), control2: CGPoint(x: 0.50 * w, y: 0.60 * h))

        return path
    }
}

#Preview {
    ZStack {
        DarkScreenBackground()
        VStack(spacing: 24) {
            PalmAuraMark(style: .capture, size: 120)
            PalmAuraMark(style: .loading(ignitionProgress: 0.56), size: 100)
        }
    }
}
