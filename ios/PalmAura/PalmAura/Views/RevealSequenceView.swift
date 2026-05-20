import SwiftUI

struct RevealSequenceView: View {
    let bundle: ReadingBundle
    private var reading: PalmReadingResponse { bundle.reading }

    @AppStorage("hasCompletedFirstReveal") private var hasCompletedFirstReveal = false
    @State private var useFirstReveal: Bool
    @State private var step = 0
    @Environment(\.navigationCoordinator) private var coordinator

    init(bundle: ReadingBundle) {
        self.bundle = bundle
        _useFirstReveal = State(initialValue: !UserDefaults.standard.bool(forKey: "hasCompletedFirstReveal"))
    }

    init(reading: PalmReadingResponse) {
        self.init(bundle: ReadingBundle.restore(reading: reading))
    }

    private var isFirstReveal: Bool { useFirstReveal }
    private var lastStep: Int { isFirstReveal ? 2 : 1 }

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Your Reading", back: false)

                Spacer(minLength: 6)

                revealContent
                    .frame(maxWidth: .infinity)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.28), value: step)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .gesture(horizontalRevealSwipe)
                    .accessibilityAction(named: Text("Next reveal card")) { advanceStep() }
                    .accessibilityAction(named: Text("Previous reveal card")) { retreatStep() }

                Spacer(minLength: 16)

                if step < lastStep {
                    GoldButton(title: nextTitle) {
                        advanceStep()
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
        .swipeBackEnabled(false)
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
                CeremonyPanel(glyph: "✦", eyebrow: answerEyebrow, title: answerTitle, detail: answerDetail)
            case 1:
                PalmIgnitionPanel(bundle: bundle)
            case 2:
                CeremonyPanel(glyph: "☽", eyebrow: "Archetype", title: reading.archetype, detail: reading.report.guidance)
            default:
                EmptyView()
            }
        } else {
            switch step {
            case 0:
                CeremonyPanel(glyph: "✦", eyebrow: answerEyebrow, title: answerTitle, detail: answerDetail)
            case 1:
                PalmIgnitionPanel(bundle: bundle)
            default:
                EmptyView()
            }
        }
    }

    private var answerEyebrow: String {
        bundle.sessionIntent?.question == nil ? "The answer begins" : "Question answered"
    }

    private var answerTitle: String {
        if let question = bundle.sessionIntent?.question, !question.isEmpty { return question }
        return reading.title
    }

    private var answerDetail: String {
        let guidance = reading.report.guidance.trimmingCharacters(in: .whitespacesAndNewlines)
        return guidance.isEmpty ? reading.oneLineSummary : guidance
    }

    private var finalActions: some View {
        VStack(spacing: 10) {
            NavigationLink {
                ReadingResultView(bundle: bundle)
            } label: {
                Text("Open full report  ›")
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

            Button {
                coordinator?.goHome()
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
            return ["Open my map  ›", "Reveal archetype  ›"][safe: step] ?? "Continue"
        } else {
            return ["Open my map  ›"][safe: step] ?? "Continue"
        }
    }

    private var horizontalRevealSwipe: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > 44, abs(horizontal) > abs(vertical) else { return }
                if horizontal < 0 {
                    advanceStep()
                } else {
                    retreatStep()
                }
            }
    }

    private func advanceStep() {
        guard step < lastStep else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation { step += 1 }
    }

    private func retreatStep() {
        guard step > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation { step -= 1 }
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
