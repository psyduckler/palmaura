import SwiftUI

struct RevealSequenceView: View {
    let bundle: ReadingBundle
    private var reading: PalmReadingResponse { bundle.reading }

    @AppStorage("hasCompletedFirstReveal") private var hasCompletedFirstReveal = false
    @State private var useFirstReveal: Bool
    @State private var step = 0
    @State private var selectedCard: ShareCard?

    init(bundle: ReadingBundle) {
        self.bundle = bundle
        _useFirstReveal = State(initialValue: !UserDefaults.standard.bool(forKey: "hasCompletedFirstReveal"))
    }

    init(reading: PalmReadingResponse) {
        self.init(bundle: ReadingBundle.restore(reading: reading))
    }

    private var isFirstReveal: Bool { useFirstReveal }
    private var lastStep: Int { isFirstReveal ? 4 : 2 }

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(
                    eyebrow: isFirstReveal ? "First Reveal" : "Your Reveal",
                    back: false,
                    trailingText: "FULL",
                    onTrailing: { showFullReport = true }
                )

                Spacer(minLength: 6)

                revealContent
                    .frame(maxWidth: .infinity)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.28), value: step)
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                Spacer(minLength: 16)

                if step < lastStep {
                    GoldButton(title: nextTitle) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation { step += 1 }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                } else {
                    finalActions
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .onAppear { hasCompletedFirstReveal = true }
                }

                stepDots
                    .padding(.top, 16)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showFullReport) { ReadingResultView(bundle: bundle) }
        .sheet(item: $selectedCard) { card in
            ShareOptionsSheet(card: card, summary: reading.oneLineSummary, bundle: bundle)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Analytics.shared.track("reveal_sequence_started", properties: ["mode": isFirstReveal ? "first" : "returning"])
        }
    }

    @State private var showFullReport = false

    @ViewBuilder
    private var revealContent: some View {
        if isFirstReveal {
            switch step {
            case 0:
                CeremonyPanel(glyph: "✦", eyebrow: "The portal opens", title: reading.title, detail: "Take a breath. Your palm has been translated into an aura snapshot for this moment.")
            case 1:
                CeremonyPanel(glyph: glyphForAura(reading.auraColor), eyebrow: "Aura color", title: reading.auraColor.rawValue.capitalized, detail: reading.report.aura)
            case 2:
                PalmIgnitionPanel(bundle: bundle)
            case 3:
                CeremonyPanel(glyph: "☽", eyebrow: "Archetype", title: reading.archetype, detail: reading.report.guidance)
            default:
                sharePanel
            }
        } else {
            switch step {
            case 0:
                CeremonyPanel(glyph: glyphForAura(reading.auraColor), eyebrow: "Aura snapshot", title: reading.title, detail: reading.oneLineSummary)
            case 1:
                PalmIgnitionPanel(bundle: bundle)
            default:
                sharePanel
            }
        }
    }

    private var sharePanel: some View {
        VStack(spacing: 14) {
            Text("Choose your share card")
                .font(DesignSystem.FontToken.display(30))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                .multilineTextAlignment(.center)
            Text("Tap a card to send your aura to stories, messages, or your camera roll.")
                .font(DesignSystem.FontToken.body(14, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(bundle.augmentedShareCards) { card in
                        ShareCardView(card: card, summary: reading.oneLineSummary)
                            .frame(width: 176, height: 308)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
                            .shadow(color: .black.opacity(0.45), radius: 22, y: 12)
                            .onTapGesture {
                                selectedCard = card
                                hasCompletedFirstReveal = true
                                Analytics.shared.track("share_card_tapped", properties: ["format": card.format.rawValue, "source": "reveal"])
                            }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }

    private var finalActions: some View {
        VStack(spacing: 10) {
            if bundle.hasPhoto {
                NavigationLink {
                    PalmMapView(bundle: bundle)
                } label: {
                    Text("Explore your palm map  ›")
                        .font(DesignSystem.FontToken.caps(11))
                        .tracking(4)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
                        .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.28), radius: 15)
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                ReadingResultView(bundle: bundle)
            } label: {
                Text("Open full report")
                    .font(DesignSystem.FontToken.caps(10))
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)

            NavigationLink {
                HomeView()
            } label: {
                Text("Return home")
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.62))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 7) {
            ForEach(0...lastStep, id: \.self) { index in
                Capsule()
                    .fill(DesignSystem.ColorToken.goldCream.opacity(index == step ? 0.9 : 0.28))
                    .frame(width: index == step ? 22 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: step)
    }

    private var nextTitle: String {
        if isFirstReveal {
            return ["Show my aura  ›", "Chart my lines  ›", "Reveal archetype  ›", "Explore + share  ›"][safe: step] ?? "Continue"
        } else {
            return ["Show signal  ›", "Choose share card  ›"][safe: step] ?? "Continue"
        }
    }

    private func glyphForAura(_ color: AuraColor) -> String {
        switch color {
        case .violet: return "♀"
        case .gold:   return "☉"
        case .fire:   return "♂"
        case .moon:   return "☽"
        case .water:  return "♆"
        case .rose:   return "♀"
        }
    }
}

private struct CeremonyPanel: View {
    let glyph: String
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 16) {
            // Glyph halo
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [DesignSystem.ColorToken.goldCream.opacity(0.32), .clear], center: .center, startRadius: 0, endRadius: 80))
                    .frame(width: 160, height: 160)
                Text(glyph)
                    .font(DesignSystem.FontToken.display(64))
                    .foregroundStyle(DesignSystem.ColorToken.goldCreamSoft)
                    .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.7), radius: 22)
            }
            Text(eyebrow.uppercased())
                .font(DesignSystem.FontToken.caps(10))
                .tracking(DesignSystem.Tracking.caps)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
            Text(title)
                .font(DesignSystem.FontToken.display(36))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(DesignSystem.FontToken.body(15))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.85))
                .padding(.horizontal, 8)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.28), lineWidth: 1)
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview { NavigationStack { RevealSequenceView(reading: LoadingReadingView.fixture()) } }
