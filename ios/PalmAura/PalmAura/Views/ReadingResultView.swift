import SwiftUI

struct ReadingResultView: View {
    let reading: PalmReadingResponse
    let bundle: ReadingBundle?

    init(reading: PalmReadingResponse) {
        self.reading = reading
        self.bundle = nil
    }

    init(bundle: ReadingBundle) {
        self.reading = bundle.reading
        self.bundle = bundle
    }

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(eyebrow: "Your Reading", back: true)
                        .padding(.horizontal, -DesignSystem.Spacing.lg)

                    // Title block
                    VStack(alignment: .leading, spacing: 10) {
                        Text(MoonPhaseProvider.currentCode + "  ·  " + ReadingTimestampFormatter.romanDate(from: reading.createdAt))
                            .font(DesignSystem.FontToken.caps(9))
                            .tracking(DesignSystem.Tracking.caps)
                            .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                        Text(reading.title)
                            .font(DesignSystem.FontToken.display(42))
                            .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                            .lineSpacing(2)
                        Text(reading.oneLineSummary)
                            .font(DesignSystem.FontToken.body(18, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                            .lineSpacing(3)
                        archetypeChip
                            .padding(.top, 2)
                    }

                    if let intent = bundle?.sessionIntent {
                        intentCard(intent)
                    }

                    // Palm map preview (if photo)
                    if let bundle, bundle.hasPhoto {
                        NavigationLink { PalmMapView(bundle: bundle) } label: {
                            mapPreview(bundle: bundle)
                        }
                        .buttonStyle(.plain)
                    }

                    // Chapters
                    chapter(glyph: "☽", title: directAnswerTitle, body: reading.report.guidance)
                    chapter(glyph: "✦", title: "Aura", body: reading.report.aura)
                    chapter(glyph: "♥", title: "Heart Line", body: reading.report.heartLine)
                    chapter(glyph: "☿", title: "Head Line", body: reading.report.headLine)
                    chapter(glyph: "♃", title: "Life Line", body: reading.report.lifeLine)
                    chapter(glyph: "♄", title: "Fate Line", body: reading.report.fateLine)
                    chapter(glyph: "☉", title: "Current Season", body: reading.report.currentSeason)
                    chapter(glyph: "⚹", title: "Ritual", body: reading.report.ritual)

                    // Footer
                    VStack(spacing: 12) {
                        OrnamentRule()
                        Text(reading.entertainmentDisclaimer)
                            .font(DesignSystem.FontToken.body(12, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 16)
                        NavigationLink { ReadingQuestionView() } label: {
                            Text("Ask another question")
                                .font(DesignSystem.FontToken.caps(11))
                                .tracking(4)
                                .textCase(.uppercase)
                                .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
                                .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.28), radius: 15)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.top, 14)
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .onAppear { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }

    private var directAnswerTitle: String {
        bundle?.sessionIntent?.question == nil ? "Guidance" : "Direct Answer"
    }

    private func intentCard(_ intent: ReadingSessionIntent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUESTION ANSWERED FIRST")
                .font(DesignSystem.FontToken.caps(9))
                .tracking(DesignSystem.Tracking.caps)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.72))
            Text(intent.displaySummary)
                .font(DesignSystem.FontToken.body(17, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }

    private var archetypeChip: some View {
        HStack(spacing: 8) {
            Text("☽")
                .font(DesignSystem.FontToken.display(14))
                .foregroundStyle(DesignSystem.ColorToken.goldCream)
            Text(reading.archetype.uppercased())
                .font(DesignSystem.FontToken.caps(10))
                .tracking(3)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.88))
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 14)
        .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.10)))
        .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.4), lineWidth: 1))
    }

    private func mapPreview(bundle: ReadingBundle) -> some View {
        HStack(spacing: 14) {
            PalmCanvasView(
                photoURL: bundle.photoURL,
                auraColor: bundle.auraColor
            )
            .frame(width: 110, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                Text("PALM MAP")
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(DesignSystem.Tracking.caps)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                Text("Open your palm map")
                    .font(DesignSystem.FontToken.display(20))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text("Your photograph, kept clean — four symbolic lenses for the full reading.")
                    .font(DesignSystem.FontToken.body(13, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
            Text("›")
                .font(DesignSystem.FontToken.display(20))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
        }
        .padding(14)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }

    private func chapter(glyph: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                GlyphCircle(glyph: glyph, size: 36)
                Text(title.uppercased())
                    .font(DesignSystem.FontToken.caps(11))
                    .tracking(3)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.88))
            }
            Text(body)
                .font(DesignSystem.FontToken.body(15))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary.opacity(0.92))
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.055))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }
}
