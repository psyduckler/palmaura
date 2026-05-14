import SwiftUI

struct PalmReviewView: View {
    let image: UIImage
    let onboardingAnswers: OnboardingAnswers
    @State private var base64: String = ""
    @State private var pendingPhotoURL: URL?

    var body: some View {
        ZStack {
            MysticalBackground()
            VStack(spacing: 18) {
                Text("Ready for your reading")
                    .font(DesignSystem.FontToken.title)
                    .multilineTextAlignment(.center)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                    .frame(maxHeight: 480)
                NavigationLink {
                    LoadingReadingView(imageBase64Jpeg: base64, pendingPhotoURL: pendingPhotoURL, onboardingAnswers: onboardingAnswers)
                } label: { Text("Reveal My Palm Reading") }
                .buttonStyle(.borderedProminent)
                .disabled(base64.isEmpty)
                Text("If your palm lines look clear and your hand fills the frame, you’re set. Otherwise, go back and retake for a sharper aura read.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DesignSystem.ColorToken.softText)
            }
            .padding(24)
        }
        .onAppear {
            if let data = ImagePreprocessor.jpegDataForUpload(from: image) {
                base64 = data.base64EncodedString()
                print("PalmAura upload JPEG bytes", data.count)
            }
            pendingPhotoURL = PalmPhotoStore.save(image, key: PalmPhotoStore.pendingKey)
        }
    }
}
