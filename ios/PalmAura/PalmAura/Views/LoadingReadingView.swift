import SwiftUI

struct LoadingReadingView: View {
    let imageBase64Jpeg: String
    let onboardingAnswers: OnboardingAnswers
    @State private var phraseIndex = 0
    @State private var reading: PalmReadingResponse?
    @State private var errorMessage: String?
    @State private var showResult = false
    private let phrases = ["Tracing your heart line…", "Listening to the mount of Venus…", "Reading your aura’s resonance…", "Aligning the lines of fate…", "Sensing your current season…", "Drawing on ancient palmistry…", "Channeling the symbols in your palm…"]

    var body: some View {
        ZStack {
            MysticalBackground()
            VStack(spacing: 28) {
                TimelineView(.animation) { context in
                    let seconds = context.date.timeIntervalSinceReferenceDate
                    ZStack {
                        Circle().stroke(.yellow.opacity(0.35), lineWidth: 2).frame(width: 210, height: 210).rotationEffect(.degrees(seconds * 28))
                        Circle().stroke(.purple.opacity(0.5), style: StrokeStyle(lineWidth: 3, dash: [8, 16])).frame(width: 160, height: 160).rotationEffect(.degrees(-seconds * 40))
                        Text("✋").font(.system(size: 72)).shadow(color: .purple, radius: 24)
                    }
                }
                Text(phrases[phraseIndex])
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.yellow).multilineTextAlignment(.center)
                    Button("Try again") { errorMessage = nil; Task { await generate() } }.buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .task { await generate() }
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            withAnimation { phraseIndex = (phraseIndex + 1) % phrases.count }
        }
        .navigationDestination(isPresented: $showResult) {
            if let reading { ReadingResultView(reading: reading) }
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
            if elapsed < 8 { try? await Task.sleep(nanoseconds: UInt64((8 - elapsed) * 1_000_000_000)) }
            await MainActor.run {
                if response.status == .ok {
                    LastReadingStore.save(response)
                    Analytics.shared.track("reading_completed", properties: ["auraColor": response.auraColor.rawValue])
                    reading = response
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

    static func fixture() -> PalmReadingResponse {
        let url = Bundle.main.url(forResource: "fixture-reading", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(PalmReadingResponse.self, from: data)
    }
}
