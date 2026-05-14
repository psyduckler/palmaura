import SwiftUI

struct PalmIgnitionPanel: View {
    let bundle: ReadingBundle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("PALM MAP")
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.yellow.opacity(0.9))
            Text("Your lines have been charted.")
                .font(.custom("Georgia", size: 34).weight(.bold))
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
            Text(bundle.shouldUsePreciseLines ? "Tap in after the reveal to explore love, mind, life, and fate." : "The oracle caught the shape of your hand; explore the symbolic map next.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Analytics.shared.track("palm_ignition_shown", properties: ["source": bundle.lineSet.source.rawValue, "confidence": String(format: "%.2f", bundle.lineSet.confidence)])
            if reduceMotion { progress = 1 } else {
                progress = 0
                withAnimation(.easeInOut(duration: 3.0)) { progress = 1 }
            }
        }
    }
}
