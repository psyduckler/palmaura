import SwiftUI

struct ReadingResultView: View {
    let reading: PalmReadingResponse
    @State private var selectedCard: ShareCard?

    var body: some View {
        ZStack {
            MysticalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack { Spacer(); NavigationLink("⚙︎") { SettingsView() }.font(.title2) }
                    Text(reading.title).font(.custom("Georgia", size: 44).weight(.bold))
                    Text(reading.oneLineSummary).font(.title3).foregroundStyle(.white.opacity(0.82))
                    Text(reading.archetype).font(.headline).foregroundStyle(.yellow)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(reading.shareCards) { card in
                                ShareCardView(card: card, summary: reading.oneLineSummary)
                                    .frame(width: 180, height: 320)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .onTapGesture { selectedCard = card; Analytics.shared.track("share_card_tapped", properties: ["format": card.format.rawValue]) }
                            }
                        }
                    }
                    report("Aura", reading.report.aura)
                    report("Heart Line", reading.report.heartLine)
                    report("Head Line", reading.report.headLine)
                    report("Life Line", reading.report.lifeLine)
                    report("Fate Line", reading.report.fateLine)
                    report("Current Season", reading.report.currentSeason)
                    report("Guidance", reading.report.guidance)
                    report("Ritual", reading.report.ritual)
                    NavigationLink("Try another reading") { OnboardingView() }.buttonStyle(.borderedProminent)
                    DisclaimerFooter()
                }.padding(24)
            }
        }
        .sheet(item: $selectedCard) { card in ShareOptionsSheet(card: card, summary: reading.oneLineSummary) }
        .onAppear { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }

    private func report(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.custom("Georgia", size: 26).weight(.bold)).foregroundStyle(.yellow.opacity(0.95))
            Text(body).foregroundStyle(.white.opacity(0.84)).lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
