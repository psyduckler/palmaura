import SwiftUI

/// 9:16 keepsake share card rendered via `ImageRenderer` and exported to the
/// share sheet / camera roll. Designed at logical 360×640 so a scale=3 render
/// produces a 1080×1920 PNG — matching Instagram Stories / TikTok specs.
///
/// Privacy: the card intentionally **omits** the user's raw question text.
/// We expose `reading.title`, `oneLineSummary`, the aura color name, and the
/// archetype — all model-derived content that's safe to broadcast. The literal
/// question the user typed in the question step stays on-device.
///
/// Layout is hand-tuned at this logical size; do not size from
/// `GeometryReader` (the parent is always 360×640 for export). Tap-targets and
/// `Dynamic Type` don't apply here — this view never appears as a live screen.
struct ShareCardView: View {
    let reading: PalmReadingResponse

    /// Logical canvas size. Render at scale=3 → 1080×1920 PNG.
    static let canvasSize = CGSize(width: 360, height: 640)

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                eyebrow
                    .padding(.top, 44)

                Spacer(minLength: 12)

                glyphHalo

                Spacer(minLength: 14)

                Text(reading.title)
                    .font(.custom("CormorantGaramond-Medium", size: 30))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 28)

                Spacer(minLength: 14)

                Text(reading.oneLineSummary)
                    .font(.custom("EBGaramond-Italic", size: 16))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .lineLimit(4)
                    .padding(.horizontal, 32)

                Spacer(minLength: 18)

                archetypeChip

                Spacer(minLength: 0)

                ornament
                    .padding(.bottom, 14)

                footer
                    .padding(.bottom, 36)
            }
            .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
        }
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
    }

    // MARK: - Components

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.ColorToken.skyDeep, DesignSystem.ColorToken.skyWarm],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [DesignSystem.ColorToken.skyIndigo.opacity(0.85), .clear],
                center: UnitPoint(x: 0.3, y: 0.2),
                startRadius: 0,
                endRadius: 260
            )
            RadialGradient(
                colors: [DesignSystem.ColorToken.skyMulberry.opacity(0.72), .clear],
                center: UnitPoint(x: 0.75, y: 0.82),
                startRadius: 0,
                endRadius: 300
            )
            RadialGradient(
                colors: [auraColor.opacity(0.32), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 240
            )
            .blendMode(.screen)
            StaticStarField()
            // Subtle inner border to feel like a card on a feed.
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .strokeBorder(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 1)
        }
    }

    private var eyebrow: some View {
        VStack(spacing: 6) {
            Text("PALMAURA")
                .font(.custom("Cinzel-Regular", size: 12).weight(.semibold))
                .tracking(DesignSystem.Tracking.capsLg)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.92))
            Text(readingTimestamp)
                .font(.custom("Cinzel-Regular", size: 9).weight(.semibold))
                .tracking(2.8)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
        }
    }

    private var glyphHalo: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.ColorToken.goldCream.opacity(0.42),
                            DesignSystem.ColorToken.goldCream.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 4)
            Circle()
                .stroke(
                    DesignSystem.ColorToken.goldCream.opacity(0.32),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 5])
                )
                .frame(width: 150, height: 150)
            Circle()
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 0.5)
                .frame(width: 110, height: 110)
            Text(auraGlyph)
                .font(.custom("CormorantGaramond-Medium", size: 64))
                .foregroundStyle(DesignSystem.ColorToken.goldCreamSoft)
                .shadow(color: auraColor.opacity(0.55), radius: 18)
                .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.45), radius: 8)
        }
        .frame(height: 200)
    }

    private var archetypeChip: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("☽")
                    .font(.custom("CormorantGaramond-Medium", size: 14))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream)
                Text(reading.archetype.uppercased())
                    .font(.custom("Cinzel-Regular", size: 10).weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.92))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.10)))
            .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.45), lineWidth: 1))

            Text(auraLabel)
                .font(.custom("Cinzel-Regular", size: 9).weight(.semibold))
                .tracking(3)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.62))
        }
    }

    private var ornament: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(DesignSystem.ColorToken.goldCream.opacity(0.35))
                .frame(width: 80, height: 0.6)
            Text("✦")
                .font(.custom("CormorantGaramond-Medium", size: 13))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.65))
            Rectangle()
                .fill(DesignSystem.ColorToken.goldCream.opacity(0.35))
                .frame(width: 80, height: 0.6)
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("FOR ENTERTAINMENT ONLY")
                .font(.custom("Cinzel-Regular", size: 8).weight(.semibold))
                .tracking(2.4)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
            Text(BrandConfig.domain)
                .font(.custom("Cinzel-Regular", size: 9).weight(.semibold))
                .tracking(3)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
        }
    }

    // MARK: - Derived

    private var auraColor: Color {
        switch reading.auraColor {
        case .violet: return .purple
        case .gold:   return .yellow
        case .fire:   return .orange
        case .moon:   return .white
        case .water:  return .cyan
        case .rose:   return .pink
        }
    }

    private var auraLabel: String {
        switch reading.auraColor {
        case .violet: return "VIOLET AURA"
        case .gold:   return "GOLDEN AURA"
        case .fire:   return "FIRE AURA"
        case .moon:   return "MOON AURA"
        case .water:  return "WATER AURA"
        case .rose:   return "ROSE AURA"
        }
    }

    private var auraGlyph: String {
        switch reading.auraColor {
        case .violet: return "☽"
        case .gold:   return "☉"
        case .fire:   return "♂"
        case .moon:   return "☾"
        case .water:  return "♆"
        case .rose:   return "♀"
        }
    }

    private var readingTimestamp: String {
        let date = ReadingTimestampFormatter.date(from: reading.createdAt) ?? Date()
        let moon = MoonPhaseProvider.code(for: date)
        let romanDate = ReadingTimestampFormatter.romanDate(from: reading.createdAt)
        return "\(moon)  ·  \(romanDate)"
    }
}

/// Deterministic, animation-free starfield used inside the share card.
/// Mirrors the visual of `StarField` but with no GeometryReader / Timeline so
/// `ImageRenderer` snapshots cleanly without main-thread surprises.
private struct StaticStarField: View {
    private let positions: [(CGPoint, CGFloat, Double)] = (0..<58).map { i in
        let x = CGFloat((i * 53 + 17) % 360)
        let y = CGFloat((i * 91 + 29) % 640)
        let r = CGFloat((i * 7) % 5) / 8.0 + 0.3
        let o = 0.40 * (0.55 + Double(i % 3) * 0.22)
        return (CGPoint(x: x, y: y), r, o)
    }

    var body: some View {
        ZStack {
            ForEach(positions.indices, id: \.self) { i in
                let (p, r, o) = positions[i]
                Circle()
                    .fill(DesignSystem.ColorToken.goldCream.opacity(o))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: p.x, y: p.y)
            }
        }
        .frame(width: ShareCardView.canvasSize.width, height: ShareCardView.canvasSize.height)
        .allowsHitTesting(false)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ShareCardView(reading: LoadingReadingView.fixture())
}
