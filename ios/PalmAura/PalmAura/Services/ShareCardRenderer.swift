import SwiftUI
import UIKit

/// Renders `ShareCardView` to a `UIImage` for export. Uses SwiftUI's
/// `ImageRenderer` (iOS 16+) — pinned to a 360×640 logical canvas at scale=3,
/// producing a 1080×1920 image (Instagram Stories / TikTok / Reels spec).
///
/// Main-actor only: `ImageRenderer` walks the SwiftUI view tree and must run
/// on the main actor. Callers should `await` from a `Task { @MainActor in … }`
/// or from a SwiftUI action closure (already main-isolated).
@MainActor
enum ShareCardRenderer {
    /// Logical canvas size — keep in sync with `ShareCardView.canvasSize`.
    /// `ImageRenderer.scale = 3` multiplies this to a 1080×1920 PNG.
    private static let scale: CGFloat = 3

    /// Render a share card for the given reading. Returns `nil` only if
    /// `ImageRenderer` fails to produce a `UIImage` (extremely rare; e.g.
    /// custom-font load failure during snapshot).
    static func renderImage(for reading: PalmReadingResponse) -> UIImage? {
        let view = ShareCardView(reading: reading)
            .frame(width: ShareCardView.canvasSize.width, height: ShareCardView.canvasSize.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        // `isOpaque = true` lets the renderer skip alpha compositing on the
        // background. Our card is fully opaque (DarkScreenBackground covers
        // the canvas), so this is a free perf+sharpness win.
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(width: ShareCardView.canvasSize.width, height: ShareCardView.canvasSize.height)
        return renderer.uiImage
    }

    /// Encode the rendered card as PNG. PNG (not JPEG) so we don't compress
    /// the gold/parchment gradients into block artifacts when users
    /// re-share or screenshot.
    static func renderPNG(for reading: PalmReadingResponse) -> Data? {
        renderImage(for: reading)?.pngData()
    }
}
