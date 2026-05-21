import SwiftUI
import UIKit
import Photos

/// Bottom sheet that lets the user save the share card to Photos or hand it
/// off to the system share sheet. Renders a live preview of `ShareCardView`
/// (downscaled — the export render at scale=3 is identical content, just at
/// 1080×1920) so users see what they're sharing before they commit.
///
/// Photo-library auth uses `.addOnly` scope — we only need the right to
/// add, never to read existing photos. Apple recommends this scope for
/// write-only flows and it's a lighter prompt for the user.
struct ShareOptionsSheet: View {
    let reading: PalmReadingResponse
    @Environment(\.dismiss) private var dismiss

    @State private var renderedImage: UIImage?
    @State private var isPreparing = true
    @State private var statusMessage: String?
    @State private var permissionDenied = false
    @State private var systemSharePresentation: ShareItemsWrapper?

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                handle
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                ScrollView {
                    VStack(spacing: 22) {
                        eyebrow
                            .padding(.top, 8)

                        cardPreview

                        if let statusMessage {
                            Text(statusMessage)
                                .font(DesignSystem.FontToken.caps(9))
                                .tracking(2.4)
                                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                                .padding(.horizontal, 12)
                        }

                        actions
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 32)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .task { await prepareImage() }
        .alert("Allow access to add photos?", isPresented: $permissionDenied) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") { openAppSettings() }
        } message: {
            Text("To save your share card to Photos, PalmAura needs permission to add photos. You can grant it in Settings.")
        }
        .sheet(item: $systemSharePresentation) { wrapper in
            SystemShareSheet(items: wrapper.items) { completed in
                if completed {
                    Analytics.shared.track("share_completed", properties: ["reading": reading.readingId])
                }
                systemSharePresentation = nil
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Components

    private var handle: some View {
        Capsule()
            .fill(DesignSystem.ColorToken.goldCream.opacity(0.32))
            .frame(width: 44, height: 4)
    }

    private var eyebrow: some View {
        VStack(spacing: 4) {
            Text("SHARE YOUR READING")
                .font(DesignSystem.FontToken.caps(11))
                .tracking(DesignSystem.Tracking.capsLg)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.92))
            Text("A keepsake card. Your question stays private.")
                .font(DesignSystem.FontToken.body(13, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var cardPreview: some View {
        if isPreparing {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(DesignSystem.ColorToken.goldCream.opacity(0.05))
                ProgressView()
                    .tint(DesignSystem.ColorToken.goldCream)
            }
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .frame(maxHeight: 360)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(0.22), lineWidth: 1)
            )
        } else if let renderedImage {
            Image(uiImage: renderedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: DesignSystem.ColorToken.skyDeep.opacity(0.6), radius: 18, x: 0, y: 8)
                .accessibilityLabel("Preview of your shareable reading card")
        } else {
            // Render failed (very rare).
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(DesignSystem.ColorToken.goldCream.opacity(0.05))
                Text("Could not prepare card.\nTry again in a moment.")
                    .font(DesignSystem.FontToken.body(13, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .frame(maxHeight: 360)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(0.22), lineWidth: 1)
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            GoldButton(title: "Share  ›") {
                presentSystemShare()
            }
            .disabled(renderedImage == nil)
            .opacity(renderedImage == nil ? 0.5 : 1)

            GhostButton(title: "Save to Photos") {
                Task { await saveToPhotos() }
            }
            .disabled(renderedImage == nil)
            .opacity(renderedImage == nil ? 0.5 : 1)

            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.62))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func prepareImage() async {
        // Rendering is main-actor work but cheap (one snapshot). Start with a
        // brief yield so the sheet's present animation isn't fighting for the
        // main thread — feels snappier on older devices.
        await Task.yield()
        let image = ShareCardRenderer.renderImage(for: reading)
        await MainActor.run {
            renderedImage = image
            isPreparing = false
            if image == nil {
                statusMessage = "Card preparation failed."
            } else {
                Analytics.shared.track("share_sheet_opened", properties: ["reading": reading.readingId])
            }
        }
    }

    private func presentSystemShare() {
        guard let renderedImage else { return }
        // Wrap both image and a URL so users get a richer share menu — the
        // image alone for camera-roll / messaging / IG, the URL for SMS /
        // mail / Twitter posts where text + link is the norm.
        var items: [Any] = [renderedImage]
        if let url = URL(string: BrandConfig.websiteURL) { items.append(url) }
        systemSharePresentation = ShareItemsWrapper(items: items)
        Analytics.shared.track("share_initiated", properties: ["reading": reading.readingId])
    }

    private func saveToPhotos() async {
        guard let renderedImage else { return }
        let status = await requestAddOnlyAuth()
        switch status {
        case .authorized, .limited:
            do {
                try await performSave(image: renderedImage)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusMessage = "Saved to Photos."
                    }
                    Analytics.shared.track("share_saved_to_photos", properties: ["reading": reading.readingId])
                }
            } catch {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    statusMessage = "Could not save. Please try again."
                    Analytics.shared.track("share_save_failed", properties: ["reading": reading.readingId])
                }
            }
        case .denied, .restricted:
            await MainActor.run {
                permissionDenied = true
                Analytics.shared.track("share_save_permission_denied")
            }
        case .notDetermined:
            // Should never hit this — `requestAddOnlyAuth` resolves the
            // pending prompt. Surface as a soft error so we don't crash.
            await MainActor.run {
                statusMessage = "Could not request permission. Please try again."
            }
        @unknown default:
            await MainActor.run {
                statusMessage = "Could not save. Please try again."
            }
        }
    }

    private func requestAddOnlyAuth() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func performSave(image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Identifiable wrapper for `[Any]` so we can present a system share sheet
/// via `.sheet(item:)`. `[Any]` itself isn't `Identifiable`.
private struct ShareItemsWrapper: Identifiable {
    let id = UUID()
    let items: [Any]
}

/// UIKit shim for `UIActivityViewController`. SwiftUI doesn't ship a native
/// share sheet on iOS 17, so we wrap the UIKit controller. The completion
/// closure fires for both completed and dismissed states; we report
/// completion to analytics, but always dismiss either way.
private struct SystemShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onCompletion: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onCompletion(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareOptionsSheet(reading: LoadingReadingView.fixture())
}
