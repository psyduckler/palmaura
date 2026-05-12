import SwiftUI

struct PalmReviewView: View {
    let image: UIImage
    let onboardingAnswers: OnboardingAnswers
    @State private var base64: String = ""
    @State private var byteCount: Int = 0

    var body: some View {
        ZStack {
            MysticalBackground()
            VStack(spacing: 18) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .frame(maxHeight: 480)
                Text("Upload size: \(byteCount / 1024) KB")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                NavigationLink {
                    LoadingReadingView(imageBase64Jpeg: base64, onboardingAnswers: onboardingAnswers)
                } label: { Text("Read My Palm") }
                .buttonStyle(.borderedProminent)
                .disabled(base64.isEmpty)
                Text("Retake if your palm lines are blurry or cropped.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(24)
        }
        .onAppear {
            if let data = ImagePreprocessor.jpegDataForUpload(from: image) {
                byteCount = data.count
                base64 = data.base64EncodedString()
                print("PalmAura upload JPEG bytes", data.count)
            }
        }
    }
}
