import SwiftUI
import UIKit

/// Sheet shown after a user taps a share card. Reskinned to the design system —
/// dark engraved-night surface, gold buttons, ghost secondaries, no SF Symbols,
/// no emoji in caption. Preserves the existing renderer, analytics, video
/// fallback, and Instagram Stories integration unchanged.
struct ShareOptionsSheet: View {
    let card: ShareCard
    let summary: String
    let bundle: ReadingBundle?

    @Environment(\.dismiss) private var dismiss
    @State private var rendered: UIImage?
    @State private var videoURL: URL?
    @State private var shareItem: ShareItem?
    @State private var isRenderingVideo = false

    init(card: ShareCard, summary: String, bundle: ReadingBundle? = nil) {
        self.card = card
        self.summary = summary
        self.bundle = bundle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DarkScreenBackground()

                VStack(spacing: 0) {
                    ScreenHeader(eyebrow: "Share Your Card", back: true) {
                        dismiss()
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            cardPreview
                                .padding(.top, 4)

                            actions
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, 36)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .task {
            let renderer = ShareCardRenderer()
            if card.format == .palmMap, let bundle {
                rendered = await renderer.renderPalmMapImage(bundle: bundle, title: card.title, summary: summary)
            } else {
                rendered = await renderer.renderImage(card: card, oneLineSummary: summary)
            }
        }
        .sheet(item: $shareItem) { item in ActivityView(items: item.items) }
    }

    // MARK: - Preview

    @ViewBuilder
    private var cardPreview: some View {
        if let rendered {
            Image(uiImage: rendered)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 460)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.32), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 32, y: 18)
        } else {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .fill(DesignSystem.ColorToken.surfaceSoft)
                .frame(maxHeight: 460)
                .overlay(
                    VStack(spacing: 14) {
                        Text("Drawing your card …")
                            .font(DesignSystem.FontToken.body(15, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        ProgressView()
                            .tint(DesignSystem.ColorToken.goldCream)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            GoldButton(title: isRenderingVideo ? "RENDERING VIDEO  ·  ·  ·" : "SHARE  ANIMATED  VIDEO  ›") {
                shareVideoPrimary()
            }
            .opacity(rendered == nil || isRenderingVideo ? 0.45 : 1)
            .disabled(rendered == nil || isRenderingVideo)

            GhostButton(title: "Save Still to Camera Roll") { save() }
                .opacity(rendered == nil ? 0.45 : 1)
                .disabled(rendered == nil)

            GhostButton(title: "Share to Instagram Stories") { shareInstagram() }
                .opacity(rendered == nil ? 0.45 : 1)
                .disabled(rendered == nil)

            GhostButton(title: "More Sharing Options") {
                if let rendered { shareItem = ShareItem(items: stillShareItems(image: rendered)) }
            }
            .opacity(rendered == nil ? 0.45 : 1)
            .disabled(rendered == nil)
        }
    }

    // MARK: - Side effects (preserved from prior implementation)

    private func shareVideoPrimary() {
        if let videoURL {
            shareItem = ShareItem(items: videoShareItems(url: videoURL))
            return
        }

        guard let rendered else { return }
        isRenderingVideo = true
        Task {
            do {
                let url = try await ShareVideoRenderer().renderVideo(from: rendered)
                await MainActor.run {
                    videoURL = url
                    shareItem = ShareItem(items: videoShareItems(url: url))
                    Analytics.shared.track("share_video_rendered", properties: ["channel": "activity_sheet"])
                }
            } catch {
                await MainActor.run {
                    shareItem = ShareItem(items: stillShareItems(image: rendered))
                    Analytics.shared.track("share_video_fallback", properties: ["reason": String(describing: error)])
                }
            }
            await MainActor.run { isRenderingVideo = false }
        }
    }

    private func save() {
        guard let rendered else { return }
        UIImageWriteToSavedPhotosAlbum(rendered, nil, nil, nil)
        Analytics.shared.track("share_completed", properties: ["channel": "camera_roll"])
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func shareInstagram() {
        guard let rendered else { return }
        if InstagramStorySharer.share(image: rendered) {
            Analytics.shared.track("share_completed", properties: ["channel": "instagram_stories"])
            dismiss()
        } else {
            shareItem = ShareItem(items: stillShareItems(image: rendered))
        }
    }

    private func stillShareItems(image: UIImage) -> [Any] { [image, shareCaption] }
    private func videoShareItems(url: URL) -> [Any] { [url, shareCaption] }

    /// Caption: replaced the previous `✨` emoji with the engraved `✦` glyph
    /// so social posts read on-brand. Hashtags preserved.
    private var shareCaption: String {
        "\(summary)\n\n✦  Read your palm at \(BrandConfig.domain)\n#palmreading #aura #mystic #fyp"
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
