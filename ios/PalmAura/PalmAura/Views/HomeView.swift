import SwiftUI

struct HomeView: View {
    @State private var lastReading = LastReadingStore.load()
    @State private var savedProfile = PersonalizationStore.load()
    private var lastBundle: ReadingBundle? { lastReading.map { ReadingBundle.restore(reading: $0) } }

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(eyebrow: "PalmAura")
                        .padding(.horizontal, -24)

                    ZStack {
                        Image("PalmPlateGold")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)
                            .opacity(0.24)
                            .offset(y: -4)
                        VStack(spacing: 14) {
                            Text("What answer")
                                .font(DesignSystem.FontToken.display(54))
                                .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                            Text("are you seeking?")
                                .font(DesignSystem.FontToken.display(48, italic: true))
                                .foregroundStyle(DesignSystem.ColorToken.goldCream)
                            Text("A vintage palmistry oracle for the story in your hands.")
                                .font(DesignSystem.FontToken.body(18, italic: true))
                                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.top, 34)
                    }
                    .frame(maxWidth: .infinity, minHeight: 330)

                    HStack(spacing: 8) {
                        ForEach(["LOVE", "WORK", "MONEY", "THE PATH"], id: \.self) { chip in
                            Text(chip)
                                .font(DesignSystem.FontToken.caps(8))
                                .tracking(2)
                                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .overlay(Capsule().stroke(DesignSystem.ColorToken.borderSoft, lineWidth: 1))
                        }
                    }
                    .frame(maxWidth: .infinity)

                    NavigationLink {
                        if savedProfile?.isCompleteProfile == true {
                            PalmCaptureView(onboardingAnswers: .forSavedProfile())
                        } else {
                            OnboardingView()
                        }
                    } label: {
                        Text(lastReading == nil ? "Ask the Palm" : "Ask Again")
                            .font(DesignSystem.FontToken.caps(11))
                            .tracking(4)
                            .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
                    }
                    .buttonStyle(.plain)

                    if let lastReading {
                        let bundle = ReadingBundle.restore(reading: lastReading)
                        ParchmentPanel {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("LAST ANSWER")
                                    .font(DesignSystem.FontToken.caps(9))
                                    .tracking(DesignSystem.Tracking.caps)
                                    .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                                Text(lastReading.title)
                                    .font(DesignSystem.FontToken.display(30))
                                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                                Text(lastReading.oneLineSummary)
                                    .font(DesignSystem.FontToken.body(16))
                                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                                    .lineSpacing(3)
                                HStack {
                                    if bundle.hasPhoto {
                                        NavigationLink("Palm Map") { PalmMapView(bundle: bundle) }
                                            .buttonStyle(.bordered)
                                    }
                                    NavigationLink("Reveal Again") { RevealSequenceView(bundle: bundle) }
                                        .buttonStyle(.bordered)
                                    NavigationLink("Full Report") { ReadingResultView(bundle: bundle) }
                                        .buttonStyle(.bordered)
                                }
                                .tint(DesignSystem.ColorToken.goldCream)
                            }
                        }
                    }

                    ParchmentPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HOW IT WORKS")
                                .font(DesignSystem.FontToken.caps(9))
                                .tracking(DesignSystem.Tracking.caps)
                                .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                            HomeBullet(icon: "I", title: "Save your profile once", detail: "Add birthday, gender, and dominant hand locally so future readings skip setup.")
                            HomeBullet(icon: "II", title: "Photograph your palm", detail: "Use a clear, well-lit photo of your open hand.")
                            HomeBullet(icon: "III", title: "Reveal the answer", detail: "Browse the snapped palm map, read the report, or share a parchment card.")
                        }
                    }

                    DisclaimerFoot()
                }
                .padding(24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { NavigationLink("Settings") { SettingsView() }.foregroundStyle(DesignSystem.ColorToken.goldCream) }
        .onAppear {
            lastReading = LastReadingStore.load()
            savedProfile = PersonalizationStore.load()
        }
    }
}

private struct HomeBullet: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(DesignSystem.FontToken.caps(9))
                .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                .frame(width: 28, height: 28)
                .background(Circle().fill(DesignSystem.ColorToken.goldCream.opacity(0.9)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(DesignSystem.FontToken.display(18)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text(detail).font(DesignSystem.FontToken.body(14)).foregroundStyle(DesignSystem.ColorToken.textSecondary)
            }
        }
    }
}

#Preview { NavigationStack { HomeView() } }
