import PhotosUI
import SwiftUI

struct PalmCaptureView: View {
    let onboardingAnswers: OnboardingAnswers
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false

    var body: some View {
        ZStack {
            MysticalBackground()
            VStack(spacing: 22) {
                Text("Scan your palm")
                    .font(DesignSystem.FontToken.display(42))
                Text("Open your hand, fill the frame, and use good lighting.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DesignSystem.ColorToken.softText)
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(DesignSystem.ColorToken.solarGold.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .frame(height: 360)
                    .overlay(PalmAuraMark(style: .capture, size: 118))
                Button("Take Photo") { showCamera = true }
                    .buttonStyle(.borderedProminent)
                PhotosPicker("Choose From Library", selection: $selectedItem, matching: .images)
                    .buttonStyle(.bordered)
            }
            .padding(24)
        }
        .sheet(isPresented: $showCamera) { CameraPicker(image: $selectedImage) }
        .onChange(of: selectedItem) { _, item in Task { await load(item) } }
        .navigationDestination(isPresented: Binding(get: { selectedImage != nil }, set: { if !$0 { selectedImage = nil } })) {
            if let selectedImage {
                PalmReviewView(image: selectedImage, onboardingAnswers: onboardingAnswers)
            }
        }
    }

    private func load(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        selectedImage = image
        Analytics.shared.track("photo_chosen")
    }
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
