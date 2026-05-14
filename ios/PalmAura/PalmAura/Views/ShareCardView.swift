import SwiftUI

/// The 1080×1920 share card exported to Stories / camera roll / activity sheet.
/// Unified vintage-engraving aesthetic across all six themes — only the aura
/// halo color varies. Designed so every shared card identifiably reads as
/// PalmAura on a feed, regardless of which card the user picked.
struct ShareCardView: View {
    let card: ShareCard
    let summary: String

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let shortSide = min(size.width, size.height)
            let titleSize = shortSide * 0.085
            let summarySize = shortSide * 0.038
            let footerSize = shortSide * 0.020

            ZStack {
                parchmentBackground(in: size)
                auraHalo(in: size)
                vignette(in: size)

                VStack(spacing: 0) {
                    Spacer(minLength: size.height * 0.08)

                    eyebrow(size: footerSize)
                    Spacer(minLength: size.height * 0.018)

                    Text(card.title)
                        .font(.custom("CormorantGaramond-Medium", size: titleSize))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.55)
                        .lineLimit(2)
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, size.width * 0.10)

                    Spacer(minLength: size.height * 0.030)
                    ornamentRule(width: size.width * 0.42)
                    Spacer(minLength: size.height * 0.024)

                    Image("PalmPlate")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width * 0.62)
                        .opacity(0.88)
                        .shadow(color: auraColor.opacity(0.36), radius: shortSide * 0.045)

                    Spacer(minLength: size.height * 0.030)

                    Text(card.body)
                        .font(.custom("CormorantGaramond-MediumItalic", size: summarySize))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .lineLimit(3)
                        .foregroundStyle(inkSoft)
                        .padding(.horizontal, size.width * 0.12)
                        .lineSpacing(summarySize * 0.18)

                    if !summary.isEmpty && summary != card.body {
                        Spacer(minLength: size.height * 0.014)
                        Text(summary)
                            .font(.custom("EBGaramond-Italic", size: summarySize * 0.72))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                            .foregroundStyle(inkSoft.opacity(0.78))
                            .padding(.horizontal, size.width * 0.14)
                            .lineSpacing(summarySize * 0.12)
                    }

                    Spacer(minLength: size.height * 0.04)
                    ornamentRule(width: size.width * 0.42)
                    Spacer(minLength: size.height * 0.022)

                    footer(size: footerSize)
                    Spacer(minLength: size.height * 0.06)
                }
                .padding(.horizontal, size.width * 0.06)

                engravedFrame(in: size)
            }
        }
    }

    // MARK: - Backgrounds

    private func parchmentBackground(in size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignSystem.ColorToken.parchmentLight,
                    DesignSystem.ColorToken.parchment,
                    DesignSystem.ColorToken.parchmentDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // subtle paper grain via stippled radial spots
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(DesignSystem.ColorToken.inkSoft.opacity(0.02))
                    .frame(width: size.width * 0.18, height: size.width * 0.18)
                    .position(
                        x: size.width * grainSeed(i, salt: 1),
                        y: size.height * grainSeed(i, salt: 7)
                    )
                    .blur(radius: 30)
            }
        }
    }

    private func auraHalo(in size: CGSize) -> some View {
        RadialGradient(
            colors: [auraColor.opacity(0.32), auraColor.opacity(0.08), .clear],
            center: .center,
            startRadius: 0,
            endRadius: min(size.width, size.height) * 0.55
        )
        .blendMode(.plusLighter)
    }

    private func vignette(in size: CGSize) -> some View {
        RadialGradient(
            colors: [.clear, DesignSystem.ColorToken.inkSoft.opacity(0.32)],
            center: .center,
            startRadius: min(size.width, size.height) * 0.45,
            endRadius: min(size.width, size.height) * 0.72
        )
    }

    private func engravedFrame(in size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .stroke(DesignSystem.ColorToken.gold.opacity(0.55), lineWidth: 1)
                .padding(size.width * 0.035)
            Rectangle()
                .stroke(DesignSystem.ColorToken.gold.opacity(0.30), lineWidth: 0.5)
                .padding(size.width * 0.045)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Type rows

    private func eyebrow(size: CGFloat) -> some View {
        HStack(spacing: 18) {
            Rectangle()
                .fill(DesignSystem.ColorToken.gold.opacity(0.55))
                .frame(width: size * 4, height: 0.7)
            Text("PALMAURA")
                .font(.custom("Cinzel-Regular", size: size).weight(.semibold))
                .tracking(size * 0.32)
                .foregroundStyle(DesignSystem.ColorToken.gold)
            Rectangle()
                .fill(DesignSystem.ColorToken.gold.opacity(0.55))
                .frame(width: size * 4, height: 0.7)
        }
    }

    private func ornamentRule(width: CGFloat) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(DesignSystem.ColorToken.gold.opacity(0.45))
                .frame(width: width * 0.42, height: 0.7)
            Text("✦")
                .font(.custom("CormorantGaramond-Medium", size: width * 0.10))
                .foregroundStyle(DesignSystem.ColorToken.gold)
            Rectangle()
                .fill(DesignSystem.ColorToken.gold.opacity(0.45))
                .frame(width: width * 0.42, height: 0.7)
        }
    }

    private func footer(size: CGFloat) -> some View {
        VStack(spacing: size * 0.6) {
            Text(BrandConfig.domain.uppercased())
                .font(.custom("Cinzel-Regular", size: size).weight(.semibold))
                .tracking(size * 0.34)
                .foregroundStyle(inkSoft)
            Text("ENTERTAINMENT ONLY")
                .font(.custom("Cinzel-Regular", size: size * 0.76).weight(.semibold))
                .tracking(size * 0.30)
                .foregroundStyle(inkSoft.opacity(0.62))
        }
    }

    // MARK: - Theme color

    /// Each ShareCardTheme gets a distinct aura halo color, but the surrounding
    /// parchment + engraved frame stays unified so the brand reads consistently.
    private var auraColor: Color {
        switch card.theme {
        case .moon: return Color(red: 0.70, green: 0.74, blue: 0.92)
        case .fire: return Color(red: 0.94, green: 0.43, blue: 0.20)
        case .water: return Color(red: 0.32, green: 0.66, blue: 0.86)
        case .gold: return DesignSystem.ColorToken.goldCream
        case .violet: return Color(red: 0.62, green: 0.36, blue: 0.86)
        case .rose: return Color(red: 0.92, green: 0.54, blue: 0.66)
        }
    }

    private var inkColor: Color { DesignSystem.ColorToken.ink }
    private var inkSoft: Color { DesignSystem.ColorToken.inkSoft }

    // Deterministic "grain" — same input always returns same offsets so the
    // ImageRenderer output is reproducible.
    private func grainSeed(_ i: Int, salt: Int) -> CGFloat {
        let raw = sin(CGFloat(i * 92 + salt * 31)) * 10000
        return abs(raw - raw.rounded(.down))
    }
}

#Preview {
    ShareCardView(
        card: ShareCard(
            format: .aura,
            title: "The Violet Wanderer",
            body: "A quiet hour. The hand has heard you.",
            accentColor: "#A07A3A",
            theme: .violet
        ),
        summary: "Heart, head, life, and fate — all in motion this season."
    )
    .frame(width: 360, height: 640)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .padding()
    .background(Color.black)
}
