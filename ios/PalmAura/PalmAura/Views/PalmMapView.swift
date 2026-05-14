import SwiftUI

struct PalmMapView: View {
    let bundle: ReadingBundle
    @State private var selectedLine: PalmLine?
    @State private var selectedCard: ShareCard?

    var body: some View {
        ZStack {
            MysticalBackground()
            VStack(spacing: 14) {
                header
                PalmCanvasView(
                    photoURL: bundle.photoURL,
                    lineSet: bundle.lineSet,
                    auraColor: bundle.auraColor,
                    activeLine: selectedLine,
                    ignitionProgress: 1,
                    renderingMode: bundle.shouldUsePreciseLines ? .preciseLines : .softGlow,
                    onSelectLine: select
                )
                .frame(maxHeight: 520)

                lineSheet
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { NavigationLink("Full report") { ReadingResultView(bundle: bundle) } }
        .sheet(item: $selectedCard) { card in ShareOptionsSheet(card: card, summary: bundle.reading.oneLineSummary, bundle: bundle) }
        .onAppear { Analytics.shared.track("palm_map_opened", properties: ["source": "map", "lineSource": bundle.lineSet.source.rawValue, "confidence": String(format: "%.2f", bundle.lineSet.confidence)]) }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Your palm map")
                .font(.custom("Georgia", size: 36).weight(.bold))
            Text(bundle.shouldUsePreciseLines ? "Tap a glowing line" : "Your palm map is symbolic — the lines are softly charted.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
            Button {
                selectedCard = bundle.augmentedShareCards.first(where: { $0.format == .palmMap })
            } label: {
                Label("Share this palm map", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .disabled(!bundle.hasPhoto)
        }
    }

    private var lineSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ForEach(PalmLine.allCases) { line in
                    Button {
                        select(line)
                    } label: {
                        Label(line.title.replacingOccurrences(of: " Line", with: ""), systemImage: line.symbolName)
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedLine == line ? .yellow : .white.opacity(0.15))
                    .foregroundStyle(selectedLine == line ? .black : .white)
                }
            }

            if let selectedLine {
                Text(selectedLine.title)
                    .font(.custom("Georgia", size: 26).weight(.bold))
                    .foregroundStyle(.yellow.opacity(0.95))
                Text(selectedLine.domain)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.55))
                Text(bundle.reading.reportText(for: selectedLine))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineSpacing(4)
                Button("Next line") { cycleNext() }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("Choose a line to browse the part of your reading it carries.")
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func select(_ line: PalmLine) {
        selectedLine = line
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Analytics.shared.track("palm_line_selected", properties: ["line": line.rawValue])
    }

    private func cycleNext() {
        let all = PalmLine.allCases
        let current = selectedLine ?? .heart
        let next = all[(all.firstIndex(of: current)! + 1) % all.count]
        selectedLine = next
        Analytics.shared.track("palm_line_cycle_next", properties: ["from": current.rawValue, "to": next.rawValue])
    }
}
