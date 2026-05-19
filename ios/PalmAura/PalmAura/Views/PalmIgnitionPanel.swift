import SwiftUI

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
                    Text("Your palm map")
                        .font(DesignSystem.FontToken.display(30))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text("is ready.")
                        .font(DesignSystem.FontToken.display(30, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                }
                .multilineTextAlignment(.center)

                PalmCanvasView(
                    photoURL: bundle.photoURL,
                    auraColor: bundle.auraColor
                )
                .frame(maxHeight: 430)
                .opacity(0.72 + (0.28 * progress))
                .scaleEffect(0.985 + (0.015 * progress))

                Text("Explore love, mind, life, and fate while your photo stays clean.")
                    .font(DesignSystem.FontToken.body(14, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 6)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Analytics.shared.track("palm_ignition_shown", properties: ["mode": "photo_map"])
            if reduceMotion {
                progress = 1
            } else {
                progress = 0
                withAnimation(.easeInOut(duration: 1.4)) { progress = 1 }
            }
        }
    }
}
