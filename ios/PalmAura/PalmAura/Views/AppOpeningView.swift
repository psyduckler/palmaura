import SwiftUI

/// First screen shown on cold start — the OrbitLoader animation plus a
/// cycling set of mystical salutation phrases. Holds for ~3 seconds then
/// calls `onDone` (typically pushes through to HomeView or DisclaimerView).
struct AppOpeningView: View {
    var onDone: () -> Void = {}

    @State private var phraseIndex = 0
    @State private var hasFinished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let phrases = [
        "Welcome back, seeker.",
        "The hand has been waiting.",
        "Tonight, the sky leans in.",
        "Bring your question close.",
        "Open your hand. Open your question."
    ]

    private let totalDuration: TimeInterval = 3.2

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "PalmAura", moon: true)
                Spacer(minLength: 12)
                OrbitLoader()
                Spacer(minLength: 24)
                Text(phrases[phraseIndex])
                    .font(DesignSystem.FontToken.body(20, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .id(phraseIndex)
                    .animation(.easeInOut(duration: 0.4), value: phraseIndex)
                    .frame(minHeight: 56)
                    .padding(.horizontal, 24)

                // Three pulsing dots beneath the status line.
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        PulsingDot(delay: Double(i) * 0.18)
                    }
                }
                .padding(.top, 12)

                Spacer()
                DisclaimerFoot()
                    .padding(.bottom, 30)
            }
        }
        .onReceive(Timer.publish(every: 0.9, on: .main, in: .common).autoconnect()) { _ in
            guard !reduceMotion else { return }
            phraseIndex = (phraseIndex + 1) % phrases.count
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(totalDuration * 1_000_000_000))
            if !hasFinished {
                hasFinished = true
                onDone()
            }
        }
    }
}

private struct PulsingDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.25

    var body: some View {
        Circle()
            .fill(DesignSystem.ColorToken.goldCream.opacity(0.6))
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever().delay(delay)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

#Preview {
    NavigationStack { AppOpeningView() }
}
