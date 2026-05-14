import SwiftUI

/// A vintage tarot-style parchment card that renders a `ShareCard` from a
/// `PalmReadingResponse`. Designed to be displayed in a horizontal scroller
/// on the reveal/result screens, and exported as a single image for sharing.
struct ShareCardView: View {
    let card: ShareCard
    let summary: String
    var size: CGSize? = nil   // when rendering for export, pass the target size

    var body: some View {
        ZStack {
            // Parchment background with subtle texture
            Rectangle()
                .fill(DesignSystem.ColorToken.parchmentLight)
                .overlay(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .clear, DesignSystem.ColorToken.gold.opacity(0.16)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // Engraved double border
            engravedBorder

            VStack(spacing: 14) {
                // Top eyebrow — date + theme
                Text(eyebrow)
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(3)
                    .foregroundStyle(DesignSystem.ColorToken.inkSoft.opacity(0.8))

                // Title
                Text(card.title)
                    .font(DesignSystem.FontToken.display(26))
                    .foregroundStyle(DesignSystem.ColorToken.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                OrnamentRuleLight()

                // Palm illustration centered
                Image("PalmPlate")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.78)
                    .frame(maxHeight: 180)

                // Quote / body
                Text(card.body.isEmpty ? summary : card.body)
                    .font(DesignSystem.FontToken.body(14, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.ink.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 6)

                Spacer(minLength: 6)

                // Planet glyphs row + footer
                HStack(spacing: 14) {
                    ForEach(themeGlyphs, id: \.self) { g in
                        Text(g)
                            .font(DesignSystem.FontToken.display(16))
                            .foregroundStyle(DesignSystem.ColorToken.goldDeep)
                    }
                }
                Text(footer)
                    .font(DesignSystem.FontToken.caps(7.5))
                    .tracking(3)
                    .foregroundStyle(DesignSystem.ColorToken.inkSoft.opacity(0.7))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Decorative

    private var engravedBorder: some View {
        ZStack {
            // Outer crisp 1px gold-deep
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(DesignSystem.ColorToken.goldDeep.opacity(0.75), lineWidth: 0.8)
                .padding(8)
            // Inner faint
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(DesignSystem.ColorToken.goldDeep.opacity(0.45), lineWidth: 0.5)
                .padding(14)
            // Tiny corner stars
            ForEach(Array(CornerStarSlot.allCases.enumerated()), id: \.offset) { _, slot in
                Text("✦")
                    .font(DesignSystem.FontToken.display(9))
                    .foregroundStyle(DesignSystem.ColorToken.goldDeep.opacity(0.7))
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: slot.alignment)
            }
        }
    }

    // MARK: - Derived

    private var eyebrow: String {
        let format = formatLabel.uppercased()
        return "\(format) · \(MoonPhaseProvider.currentCode)"
    }

    private var formatLabel: String {
        switch card.format {
        case .aura:        return "Aura"
        case .archetype:   return "Archetype"
        case .thirtyDay:   return "30-day arc"
        case .palmMap:     return "Palm map"
        }
    }

    private var themeGlyphs: [String] {
        switch card.theme {
        case .moon:    return ["☽", "♀", "✦"]
        case .fire:    return ["♂", "☉", "✦"]
        case .water:   return ["☽", "♆", "✦"]
        case .gold:    return ["☉", "♃", "✦"]
        case .violet:  return ["♄", "☿", "✦"]
        case .rose:    return ["♀", "☽", "✦"]
        }
    }

    private var footer: String { "PALMAURA · MMXXVI" }
}

// Corner slots for the engraved-frame ✦ markers. Swift's `Alignment` isn't
// Hashable, so we use a small enum to drive the ForEach.
private enum CornerStarSlot: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
    var alignment: Alignment {
        switch self {
        case .topLeading:     return .topLeading
        case .topTrailing:    return .topTrailing
        case .bottomLeading:  return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }
}

// MARK: - Ornament rule (light variant for use on parchment cards)

struct OrnamentRuleLight: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(DesignSystem.ColorToken.goldDeep.opacity(0.45)).frame(height: 0.6)
            Text("✦").font(DesignSystem.FontToken.display(12)).foregroundStyle(DesignSystem.ColorToken.goldDeep.opacity(0.75))
            Rectangle().fill(DesignSystem.ColorToken.goldDeep.opacity(0.45)).frame(height: 0.6)
        }
    }
}

#Preview {
    let sample = ShareCard(format: .aura,
                            title: "The Open Door",
                            body: "You're closer to the answer than you've been letting yourself believe.",
                            accentColor: "gold",
                            theme: .gold)
    return ShareCardView(card: sample, summary: "Closer than you think.")
        .frame(width: 220, height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 22, y: 12)
        .padding()
        .background(DesignSystem.ColorToken.skyDeep)
}
