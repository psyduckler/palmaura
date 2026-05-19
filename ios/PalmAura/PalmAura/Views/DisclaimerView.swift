import SwiftUI

struct DisclaimerView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "PalmAura", compact: true)
                Spacer(minLength: 8)

                VStack(spacing: 18) {
                    Text("·  A QUIET PROMISE  ·")
                        .font(DesignSystem.FontToken.caps(10))
                        .tracking(DesignSystem.Tracking.caps)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.7))

                    VStack(spacing: 4) {
                        Text("Before the hand")
                            .font(DesignSystem.FontToken.display(38))
                            .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                        Text("opens.")
                            .font(DesignSystem.FontToken.display(38, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.goldCream)
                    }
                    .multilineTextAlignment(.center)

                    Text("PalmAura readings are symbolic entertainment and self-reflection only. They are not medical, legal, financial, psychological, or life-critical advice.")
                        .font(DesignSystem.FontToken.body(16, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)

                    OrnamentRule().padding(.horizontal, 40).padding(.top, 6)

                    VStack(alignment: .leading, spacing: 14) {
                        bullet(glyph: "☉", body: "Bring your own judgement to every reading.")
                        bullet(glyph: "☽", body: "Your photo is processed once, then discarded.")
                        bullet(glyph: "✦", body: "Your birthday and preferences live only on this device.")
                    }
                    .padding(20)
                    .background(DesignSystem.ColorToken.goldCream.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                            .stroke(DesignSystem.ColorToken.goldCream.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                Spacer()

                VStack(spacing: 10) {
                    GoldButton(title: "I Understand  ·  Begin") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Analytics.shared.track("disclaimer_accepted")
                        disclaimerAccepted = true
                    }
                    Link("Privacy & terms", destination: URL(string: "https://palmaura.app/privacy.html")!)
                        .font(DesignSystem.FontToken.caps(9))
                        .tracking(2.5)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.6))
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func bullet(glyph: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            GlyphCircle(glyph: glyph, size: 30)
            Text(body)
                .font(DesignSystem.FontToken.body(14))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.86))
                .lineSpacing(2)
        }
    }
}

#Preview { NavigationStack { DisclaimerView() } }
