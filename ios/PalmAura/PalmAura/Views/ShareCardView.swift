import SwiftUI

struct ShareCardView: View {
    let card: ShareCard
    let summary: String

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let shortSide = min(size.width, size.height)
            let titleSize = shortSide * 0.082
            let bodySize = shortSide * 0.04
            let footerSize = shortSide * 0.022
            let horizontalPadding = size.width * 0.085

            ZStack {
                gradient(for: card.theme)

                auraRibbons(in: size)
                    .stroke(.white.opacity(0.09), lineWidth: max(2, shortSide * 0.005))
                    .blendMode(.screen)

                Circle()
                    .fill(radialGlow(for: card.theme))
                    .frame(width: size.width * 0.82, height: size.width * 0.82)
                    .blur(radius: shortSide * 0.08)
                    .opacity(0.78)

                VStack(spacing: size.height * 0.028) {
                    Spacer(minLength: size.height * 0.08)

                    Text(card.title.uppercased())
                        .font(.system(size: titleSize, weight: .black, design: .serif))
                        .tracking(titleSize * 0.045)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.48)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.26), radius: shortSide * 0.018, y: shortSide * 0.01)

                    PalmAuraMark(style: .capture, size: size.width * 0.28, showGlow: true)
                        .padding(.vertical, size.height * 0.006)

                    VStack(spacing: size.height * 0.014) {
                        Text(card.body)
                            .font(.system(size: bodySize, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.94))
                            .minimumScaleFactor(0.62)
                            .lineLimit(3)

                        if !summary.isEmpty {
                            Text(summary)
                                .font(.system(size: bodySize * 0.62, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.72))
                                .minimumScaleFactor(0.7)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: size.height * 0.06)

                    Text("\(BrandConfig.domain) · \(BrandConfig.socialHandle) · entertainment only")
                        .font(.system(size: footerSize, weight: .semibold, design: .rounded))
                        .tracking(footerSize * 0.035)
                        .foregroundStyle(.white.opacity(0.76))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, size.height * 0.055)
            }
        }
    }

    private func auraRibbons(in size: CGSize) -> Path {
        Path { path in
            for i in 0..<7 {
                let progress = CGFloat(i) / 6
                let y = size.height * (0.2 + progress * 0.62)
                path.move(to: CGPoint(x: size.width * -0.08, y: y))
                path.addCurve(
                    to: CGPoint(x: size.width * 1.08, y: y + size.height * (i.isMultiple(of: 2) ? 0.045 : -0.045)),
                    control1: CGPoint(x: size.width * 0.24, y: y - size.height * 0.085),
                    control2: CGPoint(x: size.width * 0.72, y: y + size.height * 0.095)
                )
            }
        }
    }

    private func gradient(for theme: ShareCardTheme) -> LinearGradient {
        let colors: [Color]
        switch theme {
        case .moon: colors = [Color(red: 0.06, green: 0.07, blue: 0.18), Color.indigo, Color(red: 0.36, green: 0.38, blue: 0.48)]
        case .fire: colors = [Color(red: 0.22, green: 0.03, blue: 0.08), Color.red.opacity(0.86), Color.orange]
        case .water: colors = [Color(red: 0.02, green: 0.12, blue: 0.24), Color.blue.opacity(0.88), Color.teal]
        case .gold: colors = [Color.black, Color(red: 0.34, green: 0.22, blue: 0.02), Color.yellow.opacity(0.82)]
        case .violet: colors = [Color(red: 0.12, green: 0.04, blue: 0.26), Color.purple, Color.pink.opacity(0.84)]
        case .rose: colors = [Color(red: 0.24, green: 0.05, blue: 0.15), Color.pink, Color.orange.opacity(0.54)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func radialGlow(for theme: ShareCardTheme) -> RadialGradient {
        let color: Color
        switch theme {
        case .moon: color = .white
        case .fire: color = .orange
        case .water: color = .cyan
        case .gold: color = .yellow
        case .violet: color = .pink
        case .rose: color = .pink
        }
        return RadialGradient(colors: [color.opacity(0.42), color.opacity(0.08), .clear], center: .center, startRadius: 0, endRadius: 360)
    }
}
