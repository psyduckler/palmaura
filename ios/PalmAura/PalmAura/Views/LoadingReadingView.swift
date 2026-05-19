import SwiftUI

struct LoadingReadingView: View {
    let imageBase64Jpeg: String
    let pendingPhotoURL: URL?
    let onboardingAnswers: OnboardingAnswers
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phraseIndex = 0
    @State private var bundle: ReadingBundle?
    @State private var errorMessage: String?
    @State private var showResult = false
    private let phrases = [
        "Reading the shape of your palm…",
        "Igniting the tiny constellations in your palm…",
        "Listening to the mount of Venus…",
        "Reading your aura’s resonance…",
        "Polishing the crystal ball’s Wi‑Fi signal…",
        "Mapping love, mind, life, and fate…",
        "Sensing your current season…",
        "Asking the moon for a second opinion…",
        "Drawing on ancient palmistry…",
        "Channeling the symbols in your palm…",
        "Dusting stardust off your map…"
    ]

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Reading")

                Spacer(minLength: 24)

                VStack(spacing: 22) {
                    OrbitLoader()
                    LoadingPulseDots()
                        .padding(.top, -8)
                    Text(phrases[phraseIndex])
                        .font(DesignSystem.FontToken.body(19, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                    if let intent = ReadingSessionIntent(answers: onboardingAnswers) {
                        Text("Question: \(intent.displaySummary)")
                            .font(DesignSystem.FontToken.body(13, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    if let currentErrorMessage = errorMessage {
                        Text(currentErrorMessage)
                            .font(DesignSystem.FontToken.body(15, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.goldCream)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        GoldButton(title: "Try Again  ›") { errorMessage = nil; Task { await generate() } }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                }
                .padding(24)

                Spacer(minLength: 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await generate() }
        .onReceive(Timer.publish(every: DesignSystem.Motion.phraseInterval, on: .main, in: .common).autoconnect()) { _ in
            advancePhrase()
        }
        .navigationDestination(isPresented: $showResult) {
            if let bundle { RevealSequenceView(bundle: bundle) }
        }
    }

    private func generate() async {
        Analytics.shared.track("reading_requested")
        let started = Date()
        do {
            let response: PalmReadingResponse
            if AppConfig.useFixtureReadings {
                response = Self.fixture()
            } else {
                let request = PalmReadingRequest(clientRequestId: UUID().uuidString, deviceId: DeviceID.current, appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0", locale: Locale.current.identifier, imageBase64Jpeg: imageBase64Jpeg, onboarding: onboardingAnswers)
                response = try await ReadingAPIClient().createReading(request)
            }
            let elapsed = Date().timeIntervalSince(started)
            if elapsed < DesignSystem.Motion.minimumReadingDuration { try? await Task.sleep(nanoseconds: UInt64((DesignSystem.Motion.minimumReadingDuration - elapsed) * 1_000_000_000)) }
            await MainActor.run {
                if response.status == .ok {
                    let boundURL = PalmPhotoStore.bind(to: response.readingId) ?? pendingPhotoURL
                    if let inferredHand = response.inferredScannedHand {
                        Analytics.shared.track("hand_inferred", properties: [
                            "hand": inferredHand.hand.rawValue,
                            "role": inferredHand.role.rawValue,
                            "confidence": String(format: "%.2f", inferredHand.confidence)
                        ])
                    }
                    let intent = ReadingSessionIntent(answers: onboardingAnswers)
                    ReadingIntentStore.save(intent, for: response.readingId)
                    LastReadingStore.save(response)
                    Analytics.shared.track("reading_completed", properties: [
                        "auraColor": response.auraColor.rawValue,
                        "focus": intent?.focus ?? onboardingAnswers.focus.displayName,
                        "questionProvided": String(intent?.question?.isEmpty == false)
                    ])
                    bundle = ReadingBundle(reading: response, photoURL: boundURL, sessionIntent: intent)
                    showResult = true
                } else {
                    Analytics.shared.track(response.status == .notPalm ? "reading_rejected_not_palm" : "reading_rejected_bad_image")
                    errorMessage = response.rejectionMessage ?? "The oracle needs a clearer palm. Try again with your open hand filling the frame."
                }
            }
        } catch {
            await MainActor.run {
                Analytics.shared.track("reading_failed")
                errorMessage = error.localizedDescription
            }
        }
    }

    private func advancePhrase() {
        guard !reduceMotion else {
            phraseIndex = (phraseIndex + 1) % phrases.count
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            phraseIndex = (phraseIndex + 1) % phrases.count
        }
    }

    static func fixture() -> PalmReadingResponse {
        let url = Bundle.main.url(forResource: "fixture-reading", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(PalmReadingResponse.self, from: data)
    }
}
