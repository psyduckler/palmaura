import SwiftUI
import UIKit

struct ShareOptionsSheet: View {
    let card: ShareCard
    let summary: String
    let bundle: ReadingBundle?
    @Environment(\.dismiss) private var dismiss

    init(card: ShareCard, summary: String, bundle: ReadingBundle? = nil) {
        self.card = card
        self.summary = summary
        self.bundle = bundle
    }
    @State private var rendered: UIImage?
    @State private var videoURL: URL?
    @State private var shareItem: ShareItem?
    @State private var isRenderingVideo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let rendered {
                    Image(uiImage: rendered)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                }

                Button {
                    shareVideoPrimary()
                } label: {
                    Label(isRenderingVideo ? "Rendering Video…" : "Share Animated Video", systemImage: "sparkles.tv")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(rendered == nil || isRenderingVideo)

                Button("Save Still to Camera Roll") { save() }
                    .buttonStyle(.bordered)
                    .disabled(rendered == nil)

                Button("Share Still to Instagram Stories") { shareInstagram() }
                    .buttonStyle(.bordered)
                    .disabled(rendered == nil)

                Button("Generic Still Share") {
                    if let rendered { shareItem = ShareItem(items: stillShareItems(image: rendered)) }
                }
                .buttonStyle(.bordered)
                .disabled(rendered == nil)
            }
            .padding()
            .navigationTitle("Share your card")
            .navigationBarTitleDisplayMode(.inline)
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

    private func stillShareItems(image: UIImage) -> [Any] {
        [image, shareCaption]
    }

    private func videoShareItems(url: URL) -> [Any] {
        [url, shareCaption]
    }

    private var shareCaption: String {
        "\(summary)\n\n✨ Get your palm read at \(BrandConfig.domain)\n#palmreading #aura #mystic #fyp"
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
