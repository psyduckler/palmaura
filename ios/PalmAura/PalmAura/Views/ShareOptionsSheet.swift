import SwiftUI
import UIKit

struct ShareOptionsSheet: View {
    let card: ShareCard
    let summary: String
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: UIImage?
    @State private var shareItem: ShareItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let rendered { Image(uiImage: rendered).resizable().scaledToFit().frame(maxHeight: 420).clipShape(RoundedRectangle(cornerRadius: 24)) }
                Button("Save to Camera Roll") { save() }.buttonStyle(.borderedProminent)
                Button("Share to Instagram Stories") { shareInstagram() }.buttonStyle(.bordered)
                Button("Generic Share") { if let rendered { shareItem = ShareItem(image: rendered) } }.buttonStyle(.bordered)
            }.padding().navigationTitle("Share your card").navigationBarTitleDisplayMode(.inline)
        }
        .task { rendered = await ShareCardRenderer().renderImage(card: card, oneLineSummary: summary) }
        .sheet(item: $shareItem) { item in ActivityView(items: [item.image, "\(summary)\n\n✨ Get your palm read at \(BrandConfig.domain)\n#palmreading #aura #mystic #fyp"]) }
    }

    private func save() { guard let rendered else { return }; UIImageWriteToSavedPhotosAlbum(rendered, nil, nil, nil); Analytics.shared.track("share_completed", properties: ["channel":"camera_roll"]); UINotificationFeedbackGenerator().notificationOccurred(.success) }
    private func shareInstagram() { guard let rendered else { return }; if InstagramStorySharer.share(image: rendered) { Analytics.shared.track("share_completed", properties: ["channel":"instagram_stories"]); dismiss() } else { shareItem = ShareItem(image: rendered) } }
}

struct ShareItem: Identifiable { let id = UUID(); let image: UIImage }

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
