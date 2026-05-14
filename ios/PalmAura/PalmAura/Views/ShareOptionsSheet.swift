import SwiftUI

struct ShareOptionsSheet: View {
    let card: ShareCard
    let summary: String
    let bundle: ReadingBundle?
    @Environment(\.dismiss) private var dismiss
    @State private var showSystemShare = false

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 18) {
                handle
                ScreenHeader(eyebrow: "Your Aura Card", moon: false)
                    .padding(.horizontal, -DesignSystem.Spacing.lg)

                Text("Tap and hold to save · swipe to share")
                    .font(DesignSystem.FontToken.body(13, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)

                ShareCardView(card: card, summary: summary)
                    .aspectRatio(0.6, contentMode: .fit)
                    .frame(maxHeight: 460)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 28, y: 14)
                    .padding(.horizontal, 36)

                Spacer(minLength: 12)

                HStack(spacing: 10) {
                    actionButton(glyph: "↓", title: "Save",   action: saveToLibrary)
                    actionButton(glyph: "✉", title: "Message", action: { showSystemShare = true })
                    primaryShareButton
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)

                Button("Close") { dismiss() }
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.6))
                    .padding(.bottom, 24)
            }
            .padding(.top, 8)
        }
        .sheet(isPresented: $showSystemShare) {
            ShareSheet(items: [renderCard(), card.body.isEmpty ? summary : card.body])
        }
    }

    private var handle: some View {
        Capsule()
            .fill(DesignSystem.ColorToken.goldCream.opacity(0.25))
            .frame(width: 40, height: 4)
            .padding(.bottom, 6)
    }

    private func actionButton(glyph: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(glyph).font(DesignSystem.FontToken.display(15))
                Text(title)
                    .font(DesignSystem.FontToken.caps(10))
                    .tracking(3)
                    .textCase(.uppercase)
            }
            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.86))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var primaryShareButton: some View {
        Button {
            showSystemShare = true
            Analytics.shared.track("share_card_share_tapped", properties: ["format": card.format.rawValue])
        } label: {
            HStack(spacing: 8) {
                Text("↗").font(DesignSystem.FontToken.display(15))
                Text("Share  ›")
                    .font(DesignSystem.FontToken.caps(11))
                    .tracking(4)
                    .textCase(.uppercase)
            }
            .foregroundStyle(DesignSystem.ColorToken.skyDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
            .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.28), radius: 15)
        }
        .buttonStyle(.plain)
    }

    private func saveToLibrary() {
        let image = renderCard()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        Analytics.shared.track("share_card_saved", properties: ["format": card.format.rawValue])
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func renderCard() -> UIImage {
        let renderer = ImageRenderer(content:
            ShareCardView(card: card, summary: summary)
                .frame(width: 1080, height: 1620)
        )
        renderer.scale = 1
        return renderer.uiImage ?? UIImage()
    }
}

/// Thin wrapper around `UIActivityViewController` for SwiftUI.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
