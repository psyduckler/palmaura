import SwiftUI
import UIKit

@MainActor
final class ShareCardRenderer {
    func renderImage(card: ShareCard, oneLineSummary: String) -> UIImage? {
        let view = ShareCardView(card: card, summary: oneLineSummary)
            .frame(width: 1080, height: 1920)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }
}
