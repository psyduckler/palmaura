import SwiftUI

/// The "your lines have been charted" reveal interstitial. Restyled to the
/// design system — `goldCream` replaces `.yellow`, `FontToken.display` replaces
/// inline Georgia, `ParchmentPanel` replaces the `.white.opacity(0.08)`
/// surface. Animation, analytics, photo URL passthrough preserved exactly.
struct PalmIgnitionPanel: View {
    let bundle: ReadingBundle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        ParchmentPanel {
            VStack(spacing: 16) {
                Text("PALM  ·  MAP")
                    .font(DesignSystem.FontToken.caps(10))
                    .tracking(DesignSystem.Tracking.caps)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.86))

                VStack(spacing: 4) {
                    Text("Your lines")
                        .font(DesignSystem.FontToken.display(30))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text("have been charted.")
                        .font(DesignSystem.FontToken.display(30, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                }
                .multilineTextAlignment(.center)

                PalmCanvasView(
                    photoURL: bundle.photoURL,
                    lineSet: bundle.lineSet,
                    auraColor: bundle.auraColor,
                    activeLine: nil,
                    ignitionProgress: progress,
                    renderingMode: bundle.shouldUsePreciseLines ? .preciseLines : .softGlow
                )
                .frame(maxHeight: 430)

                Text(bundle.shouldUsePreciseLines
                     ? "Tap in after the reveal to explore love, mind, life, and fate."
                     : "The oracle caught the shape of your hand; explore the symbolic map next.")
                    .font(DesignSystem.FontToken.body(14, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 6)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Analytics.shared.track("palm_ignition_shown", properties: [
                "source": bundle.lineSet.source.rawValue,
                "confidence": String(format: "%.2f", bundle.lineSet.confidence)
            ])
            if reduceMotion {
                progress = 1
            } else {
                progress = 0
                withAnimation(.easeInOut(duration: 3.0)) { progress = 1 }
            }
        }
    }
}
