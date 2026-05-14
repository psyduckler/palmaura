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
            MysticalBackground()
            VStack(spacing: 26) {
                HStack {
                    Text(isFirstReveal ? "First reveal" : "Your reveal")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.6)
                        .foregroundStyle(.yellow.opacity(0.85))
                    Spacer()
                    NavigationLink("Full report") { ReadingResultView(bundle: bundle) }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer(minLength: 12)

                revealContent
                    .frame(maxWidth: .infinity)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.28), value: step)

                Spacer(minLength: 12)

                if step < lastStep {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation { step += 1 }
                    } label: {
                        Text(nextTitle)
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                } else {
                    finalActions
                        .onAppear { hasCompletedFirstReveal = true }
                }

                stepDots
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $selectedCard) { card in
            ShareOptionsSheet(card: card, summary: reading.oneLineSummary, bundle: bundle)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Analytics.shared.track("reveal_sequence_started", properties: ["mode": isFirstReveal ? "first" : "returning"])
        }
    }

    @ViewBuilder
    private var revealContent: some View {
        if isFirstReveal {
            switch step {
            case 0:
                CeremonyPanel(emoji: "✨", eyebrow: "The portal opens", title: reading.title, detail: "Take a breath. Your palm has been translated into an aura snapshot for this moment.")
            case 1:
                CeremonyPanel(emoji: auraEmoji, eyebrow: "Aura color", title: reading.auraColor.rawValue.capitalized, detail: reading.report.aura)
            case 2:
                PalmIgnitionPanel(bundle: bundle)
            case 3:
                CeremonyPanel(emoji: "🔮", eyebrow: "Archetype", title: reading.archetype, detail: reading.report.guidance)
            default:
                sharePanel
            }
        } else {
            switch step {
            case 0:
                CeremonyPanel(emoji: auraEmoji, eyebrow: "Aura snapshot", title: reading.title, detail: reading.oneLineSummary)
            case 1:
                PalmIgnitionPanel(bundle: bundle)
            default:
                sharePanel
            }
        }
    }

    private var sharePanel: some View {
        VStack(spacing: 18) {
            Text("Choose your share card")
                .font(.custom("Georgia", size: 34).weight(.bold))
                .multilineTextAlignment(.center)
            Text("Tap a card to send your aura to stories, messages, or your camera roll.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(bundle.augmentedShareCards) { card in
                        ShareCardView(card: card, summary: reading.oneLineSummary)
                            .frame(width: 176, height: 312)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.28), radius: 18, y: 12)
                            .onTapGesture {
                                selectedCard = card
                                hasCompletedFirstReveal = true
                                Analytics.shared.track("share_card_tapped", properties: ["format": card.format.rawValue, "source": "reveal"])
                            }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 8)
            }
        }
    }

    private var finalActions: some View {
        VStack(spacing: 12) {
            if bundle.hasPhoto {
                NavigationLink {
                    PalmMapView(bundle: bundle)
                } label: {
                    Text("Explore your palm map")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            NavigationLink {
                ReadingResultView(bundle: bundle)
            } label: {
                Text("Open full report")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            NavigationLink("Return home") { HomeView() }
                .buttonStyle(.bordered)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastStep, id: \.self) { index in
                Capsule()
                    .fill(index == step ? .yellow : .white.opacity(0.25))
                    .frame(width: index == step ? 22 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: step)
    }

    private var nextTitle: String {
        if isFirstReveal {
            return ["Show my aura", "Chart my lines", "Reveal archetype", "Explore + share"][safe: step] ?? "Continue"
        } else {
            return ["Show signal", "Choose share card"][safe: step] ?? "Continue"
        }
    }

    private var auraEmoji: String {
        switch reading.auraColor {
        case .violet: return "💜"
        case .gold: return "🌟"
        case .fire: return "🔥"
        case .moon: return "🌙"
        case .water: return "🌊"
        case .rose: return "🌹"
        }
    }
}

private struct CeremonyPanel: View {
    let emoji: String
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 18) {
            Text(emoji)
                .font(.system(size: 78))
                .shadow(color: .purple, radius: 24)
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(.yellow.opacity(0.86))
            Text(title)
                .font(.custom("Georgia", size: 40).weight(.bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.yellow.opacity(0.22), lineWidth: 1)
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview { NavigationStack { RevealSequenceView(reading: LoadingReadingView.fixture()) } }
