import SwiftUI

struct PalmReviewView: View {
    let image: UIImage
    let onboardingAnswers: OnboardingAnswers
    @State private var base64: String = ""
    @State private var pendingPhotoKey = PalmPhotoStore.makePendingKey()
    @State private var pendingPhotoURL: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Review", back: true)

                VStack(alignment: .center, spacing: 6) {
                    Text("Is this your")
                        .font(DesignSystem.FontToken.display(34))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text("hand?")
                        .font(DesignSystem.FontToken.display(34, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                    Text("We'll only read what we can see clearly.")
                        .font(DesignSystem.FontToken.body(14, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, 6)
                .padding(.bottom, 22)

                photoCard
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                if let intent = ReadingSessionIntent(answers: onboardingAnswers) {
                    intentChip(intent)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, 14)
                }

                Spacer(minLength: 16)

                actions
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .task(id: pendingPhotoKey) {
            // Process image and write to disk on a background thread to prevent UI freezing.
            // Each review attempt writes to its own pending key so an abandoned retake cannot
            // overwrite a newer photo that is already being submitted.
            let key = pendingPhotoKey
            let (b64, url) = await Task.detached(priority: .userInitiated) {
                let uploadData = ImagePreprocessor.jpegDataForUpload(from: image)
                let base64String = uploadData?.base64EncodedString() ?? ""
                let photoURL = PalmPhotoStore.save(image, key: key)
                return (base64String, photoURL)
            }.value

            guard !Task.isCancelled else { return }
            withAnimation {
                self.base64 = b64
                self.pendingPhotoURL = url
            }
        }
    }

    private var photoCard: some View {
        ZStack {
            // Sepia-toned print: warm parchment-deep background, photo with sepia filter on top.
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .fill(DesignSystem.ColorToken.parchmentDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.55), radius: 30, y: 14)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
                .saturation(0.78)
                .contrast(1.05)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                        .fill(LinearGradient(colors: [DesignSystem.ColorToken.gold.opacity(0.18), .clear],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .blendMode(.multiply)
                )

            // Status chip pinned bottom
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Text("✦").font(DesignSystem.FontToken.display(13)).foregroundStyle(DesignSystem.ColorToken.goldCream)
                    Text("Your palm fills the frame.")
                        .font(DesignSystem.FontToken.body(13, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(Capsule().fill(DesignSystem.ColorToken.skyDeep.opacity(0.78)))
                .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.32), lineWidth: 0.5))
                .padding(.bottom, 14)
            }
        }
        .frame(height: 480)
    }

    private func intentChip(_ intent: ReadingSessionIntent) -> some View {
        HStack(spacing: 10) {
            Text("✦")
                .font(DesignSystem.FontToken.display(16))
                .foregroundStyle(DesignSystem.ColorToken.goldCream)
            Text(intent.displaySummary)
                .font(DesignSystem.FontToken.body(13, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.9))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.08)))
        .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.24), lineWidth: 0.5))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            NavigationLink {
                LoadingReadingView(imageBase64Jpeg: base64, pendingPhotoKey: pendingPhotoKey, pendingPhotoURL: pendingPhotoURL, onboardingAnswers: onboardingAnswers)
            } label: {
                Text(base64.isEmpty ? "Preparing…" : "Read My Palm  ›")
                    .font(DesignSystem.FontToken.caps(11))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
                    .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.28), radius: 15)
                    .opacity(base64.isEmpty ? 0.5 : 1)
            }
            .buttonStyle(.plain)
            .disabled(base64.isEmpty)

            GhostButton(title: "Retake the Photo") {
                dismiss()
            }
        }
    }
}
