import SwiftUI

struct PalmMapView: View {
    let bundle: ReadingBundle
    @State private var selectedLine: PalmLine?

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(
                    eyebrow: "Your Hand · Mapped",
                    back: true,
                    trailingText: "FULL",
                    onTrailing: { showFullReport = true }
                )

                titleBlock
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 14)

                PalmCanvasView(
                    photoURL: bundle.photoURL,
                    lineSet: bundle.lineSet,
                    auraColor: bundle.auraColor,
                    activeLine: selectedLine,
                    ignitionProgress: 1,
                    renderingMode: bundle.shouldUsePreciseLines ? .preciseLines : .softGlow,
                    onSelectLine: select
                )
                .frame(maxHeight: 460)
                .padding(.horizontal, DesignSystem.Spacing.lg)

                Spacer(minLength: 14)

                lineSheet
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showFullReport) {
            ReadingResultView(bundle: bundle)
        }
        .onAppear {
            Analytics.shared.track("palm_map_opened", properties: [
                "source": "map",
                "lineSource": bundle.lineSet.source.rawValue,
                "confidence": String(format: "%.2f", bundle.lineSet.confidence)
            ])
        }
    }

    @State private var showFullReport = false

    private var titleBlock: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(spacing: 6) {
                Text("Four lines.")
                    .font(DesignSystem.FontToken.display(28))
                Text("Six mounts.")
                    .font(DesignSystem.FontToken.display(28, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream)
            }
            .foregroundStyle(DesignSystem.ColorToken.textPrimary)
            Text(bundle.sessionIntent?.question == nil
                 ? (bundle.shouldUsePreciseLines ? "Tap a glowing line to read what it carries." : "Your map is symbolic — the lines are softly charted.")
                 : "Tap a glowing line to read what it contributes to this question.")
                .font(DesignSystem.FontToken.body(13, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var lineSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let intent = bundle.sessionIntent {
                Text(intent.displaySummary)
                    .font(DesignSystem.FontToken.body(13, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                    .lineLimit(2)
                    .padding(.bottom, 2)
            }
            // Chip row of all 4 lines
            HStack(spacing: 8) {
                ForEach(PalmLine.allCases) { line in
                    LineChip(line: line, selected: selectedLine == line) { select(line) }
                }
            }

            if let selectedLine {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLine.title)
                        .font(DesignSystem.FontToken.display(24))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text(selectedLine.domain.uppercased())
                        .font(DesignSystem.FontToken.caps(9))
                        .tracking(2.5)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.72))
                    Text(bundle.reading.reportText(for: selectedLine))
                        .font(DesignSystem.FontToken.body(14))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.92))
                        .lineSpacing(3)
                }
                GhostButton(title: "Next line", action: { cycleNext() }, leading: "›")
            } else {
                Text("Choose a line to read the part of your answer it carries.")
                    .font(DesignSystem.FontToken.body(14, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(18)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.075))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.26), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
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

/// Vintage glyph chip used to select one of the 4 palm lines.
private struct LineChip: View {
    let line: PalmLine
    let selected: Bool
    let action: () -> Void

    private var glyph: String {
        switch line {
        case .heart: return "♥"
        case .head:  return "☿"
        case .life:  return "♃"
        case .fate:  return "✦"
        }
    }
    private var short: String {
        switch line {
        case .heart: return "Heart"
        case .head:  return "Head"
        case .life:  return "Life"
        case .fate:  return "Fate"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(glyph)
                    .font(DesignSystem.FontToken.display(18))
                    .foregroundStyle(selected ? DesignSystem.ColorToken.skyDeep : DesignSystem.ColorToken.goldCream)
                Text(short)
                    .font(DesignSystem.FontToken.caps(8.5))
                    .tracking(2)
                    .foregroundStyle(selected ? DesignSystem.ColorToken.skyDeep : DesignSystem.ColorToken.goldCream.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? DesignSystem.ColorToken.goldCream.opacity(0.92) : DesignSystem.ColorToken.goldCream.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.85 : 0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
