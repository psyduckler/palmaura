import PhotosUI
import SwiftUI

struct PalmCaptureView: View {
    let onboardingAnswers: OnboardingAnswers
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Capture · Your Palm", back: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lay your hand")
                        .font(DesignSystem.FontToken.display(36))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text("open.")
                        .font(DesignSystem.FontToken.display(36, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                    Text("Fingers gently spread. Soft, even light. Hand fills the frame.")
                        .font(DesignSystem.FontToken.body(15, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, 8)
                .padding(.bottom, 18)

                viewfinderCard
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                Spacer(minLength: 18)

                actionStack
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCamera) { CameraPicker(image: $selectedImage) }
        .onChange(of: selectedItem) { _, item in Task { await load(item) } }
        .navigationDestination(isPresented: Binding(get: { selectedImage != nil }, set: { if !$0 { selectedImage = nil } })) {
            if let selectedImage {
                PalmReviewView(image: selectedImage, onboardingAnswers: onboardingAnswers)
            }
        }
    }

    private var viewfinderCard: some View {
        ZStack {
            // Engraved frame
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.35), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 0.5)
                        .padding(8)
                )

            // Corner ticks
            CornerTicks(color: DesignSystem.ColorToken.goldCream.opacity(0.85), inset: 16, size: 22, thickness: 1.5)

            // Palm silhouette guide
            Image("PalmPlateGold")
                .resizable()
                .scaledToFit()
                .opacity(0.28)
                .padding(.horizontal, 28)
                .padding(.vertical, 28)

            // Alignment chip
            VStack {
                Spacer()
                Text("ALIGNING · OPEN PALM")
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.16)))
                    .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.4), lineWidth: 0.6))
                    .padding(.bottom, 18)
            }
        }
        .frame(height: 440)
    }

    private var actionStack: some View {
        VStack(spacing: 12) {
            GoldButton(title: "Take Photo") { showCamera = true }
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 8) {
                    Text("❑").font(DesignSystem.FontToken.display(15))
                    Text("Choose From Library")
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
    }

    private func load(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        selectedImage = image
        Analytics.shared.track("photo_chosen")
    }
}

/// Four L-shaped corner ticks that frame a viewfinder.
private struct CornerTicks: View {
    let color: Color
    let inset: CGFloat
    let size: CGFloat
    let thickness: CGFloat
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // top-left
            tick(at: CGPoint(x: inset, y: inset), corners: [.topLeading])
            // top-right
            tick(at: CGPoint(x: w - inset - size, y: inset), corners: [.topTrailing])
            // bottom-left
            tick(at: CGPoint(x: inset, y: h - inset - size), corners: [.bottomLeading])
            // bottom-right
            tick(at: CGPoint(x: w - inset - size, y: h - inset - size), corners: [.bottomTrailing])
        }
        .allowsHitTesting(false)
    }
    private func tick(at p: CGPoint, corners: Set<Corner>) -> some View {
        Path { path in
            // horizontal segment
            let yEdge = corners.contains(.topLeading) || corners.contains(.topTrailing) ? p.y : p.y + size
            let xStart: CGFloat = corners.contains(.topLeading) || corners.contains(.bottomLeading) ? p.x : p.x + size * 0.45
            let xEnd: CGFloat = corners.contains(.topLeading) || corners.contains(.bottomLeading) ? p.x + size * 0.55 : p.x + size
            path.move(to: CGPoint(x: xStart, y: yEdge))
            path.addLine(to: CGPoint(x: xEnd, y: yEdge))
            // vertical segment
            let xEdge = corners.contains(.topLeading) || corners.contains(.bottomLeading) ? p.x : p.x + size
            let yStart: CGFloat = corners.contains(.topLeading) || corners.contains(.topTrailing) ? p.y : p.y + size * 0.45
            let yEnd: CGFloat = corners.contains(.topLeading) || corners.contains(.topTrailing) ? p.y + size * 0.55 : p.y + size
            path.move(to: CGPoint(x: xEdge, y: yStart))
            path.addLine(to: CGPoint(x: xEdge, y: yEnd))
        }
        .stroke(color, style: .init(lineWidth: thickness, lineCap: .round))
    }
    enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }
}

struct ImageSelection: Identifiable { let id = UUID(); let image: UIImage }

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            Analytics.shared.track("photo_captured")
            parent.dismiss()
        }
    }
}
