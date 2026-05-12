import SwiftUI

struct ShareCardView: View {
    let card: ShareCard
    let summary: String

    var body: some View {
        ZStack {
            gradient(for: card.theme).ignoresSafeArea()
            ForEach(0..<7, id: \.self) { i in
                Path { path in
                    let y = CGFloat(420 + i * 120)
                    path.move(to: CGPoint(x: 120, y: y))
                    path.addCurve(to: CGPoint(x: 960, y: y + CGFloat((i % 2 == 0) ? 80 : -80)), control1: CGPoint(x: 360, y: y - 160), control2: CGPoint(x: 700, y: y + 180))
                }.stroke(.white.opacity(0.08), lineWidth: 5)
            }
            VStack(spacing: 38) {
                Spacer()
                Text(card.title).font(.custom("Georgia", size: 92).weight(.bold)).multilineTextAlignment(.center).minimumScaleFactor(0.55)
                Text(card.body).font(.system(size: 44, weight: .semibold)).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.9))
                Spacer()
                VStack(spacing: 10) {
                    Text(BrandConfig.socialHandle).font(.system(size: 34, weight: .bold))
                    Text("\(BrandConfig.shortDisclaimer) • \(BrandConfig.domain)").font(.system(size: 24)).foregroundStyle(.white.opacity(0.7))
                }
            }.padding(80)
        }
    }

    private func gradient(for theme: ShareCardTheme) -> LinearGradient {
        let colors: [Color]
        switch theme {
        case .moon: colors = [Color.indigo, Color.gray]
        case .fire: colors = [Color.red.opacity(0.75), Color.orange]
        case .water: colors = [Color.blue.opacity(0.85), Color.teal]
        case .gold: colors = [Color.black, Color.yellow.opacity(0.75)]
        case .violet: colors = [Color.purple, Color.pink]
        case .rose: colors = [Color.pink, Color.orange.opacity(0.45)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
