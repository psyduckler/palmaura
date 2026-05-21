import SwiftUI

/// Past-readings library. Lists every reading saved on this device,
/// newest first, capped at `ReadingHistoryStore.maxReadings`. Each row
/// opens the full `ReadingResultView` for that reading; long-press
/// reveals a delete affordance.
///
/// Surfaced from:
/// - `HomeView` "Past Readings" button (when at least one reading exists)
/// - `SettingsView` "Library of readings" navRow (always available)
struct ReadingsLibraryView: View {
    @State private var readings: [PalmReadingResponse] = []
    @State private var pendingDeletionId: String?

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(eyebrow: "Past Readings", back: true)
                        .padding(.horizontal, -DesignSystem.Spacing.lg)

                    intro

                    if readings.isEmpty {
                        emptyState
                    } else {
                        ForEach(readings) { reading in
                            row(for: reading)
                        }
                    }

                    DisclaimerFoot()
                        .padding(.top, 16)
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .onAppear(perform: reload)
        .alert(
            "Delete this reading?",
            isPresented: Binding(
                get: { pendingDeletionId != nil },
                set: { if !$0 { pendingDeletionId = nil } }
            ),
            presenting: pendingDeletionId
        ) { id in
            Button("Cancel", role: .cancel) { pendingDeletionId = nil }
            Button("Delete", role: .destructive) { performDelete(readingId: id) }
        } message: { _ in
            Text("The reading, palm photo, and session question are removed from this device. This can't be undone.")
        }
    }

    // MARK: - Sections

    private var intro: some View {
        VStack(spacing: 6) {
            Text("·  KEEPSAKES  ·")
                .font(DesignSystem.FontToken.caps(9))
                .tracking(DesignSystem.Tracking.caps)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.72))
                .accessibilityHidden(true)
            Text("Your past readings")
                .font(DesignSystem.FontToken.display(30))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary)
            Text("Up to \(ReadingHistoryStore.maxReadings) readings stay on this device. Long-press a reading to delete it.")
                .font(DesignSystem.FontToken.body(13, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        ParchmentPanel {
            VStack(spacing: 14) {
                GlyphCircle(glyph: "☽", size: 48, selected: true)
                Text("No readings yet.")
                    .font(DesignSystem.FontToken.display(22))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text("Once you ask the palm, every reading lands here.")
                    .font(DesignSystem.FontToken.body(14, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for reading: PalmReadingResponse) -> some View {
        let bundle = ReadingBundle.restore(reading: reading)
        NavigationLink {
            ReadingResultView(bundle: bundle)
        } label: {
            HStack(spacing: 14) {
                thumbnail(for: bundle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(reading.title)
                        .font(DesignSystem.FontToken.display(20))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    Text(metaLine(for: reading))
                        .font(DesignSystem.FontToken.caps(8.5))
                        .tracking(2)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.72))
                    Text(InlineMarkdownFormatter.bodyAttributedString(from: reading.oneLineSummary, size: 13, baseItalic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Text("›")
                    .font(DesignSystem.FontToken.display(20))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(DesignSystem.ColorToken.goldCream.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the full reading")
        .contextMenu {
            Button(role: .destructive) {
                Analytics.shared.track("reading_history_delete_prompt", properties: ["readingId": reading.readingId])
                pendingDeletionId = reading.readingId
            } label: {
                Label("Delete reading", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func thumbnail(for bundle: ReadingBundle) -> some View {
        let auraTint = swiftUIColor(for: bundle.auraColor)
        if bundle.hasPhoto, let photoURL = bundle.photoURL, let image = UIImage(contentsOfFile: photoURL.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(auraTint.opacity(0.18))
                        .blendMode(.screen)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.32), lineWidth: 0.6)
                )
                .accessibilityHidden(true)
        } else {
            // Fallback used when the photo file has been pruned/cleared
            // but the reading JSON survives, or when older readings had
            // no bound photo.
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    colors: [auraTint.opacity(0.35), DesignSystem.ColorToken.skyDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(glyph(for: bundle.auraColor))
                        .font(DesignSystem.FontToken.display(26))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                        .accessibilityHidden(true)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.32), lineWidth: 0.6)
                )
                .accessibilityHidden(true)
        }
    }

    // MARK: - Actions

    private func reload() {
        readings = ReadingHistoryStore.allReadings()
    }

    private func performDelete(readingId: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        ReadingHistoryStore.delete(readingId: readingId)
        pendingDeletionId = nil
        withAnimation(.snappy) { reload() }
        Analytics.shared.track("reading_history_delete_confirmed", properties: ["readingId": readingId])
    }

    // MARK: - Derived display

    /// `13 MAY 2026 · RELATIONSHIP` style. Uses the parsed `createdAt`
    /// from the reading JSON; falls back to current date if parsing
    /// fails (defensive, shouldn't happen for server-issued readings).
    private func metaLine(for reading: PalmReadingResponse) -> String {
        let date = ReadingTimestampFormatter.date(from: reading.createdAt) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        let dateString = formatter.string(from: date).uppercased()

        let focus = ReadingIntentStore.load(for: reading.readingId)?.focus.uppercased()
        if let focus, !focus.isEmpty {
            return "\(dateString)  ·  \(focus)"
        }
        return dateString
    }

    private func glyph(for aura: AuraColor) -> String {
        switch aura {
        case .violet: return "♇"
        case .gold:   return "☉"
        case .fire:   return "♂"
        case .moon:   return "☽"
        case .water:  return "♆"
        case .rose:   return "♀"
        }
    }

    private func swiftUIColor(for aura: AuraColor) -> Color {
        switch aura {
        case .violet: return .purple
        case .gold:   return .yellow
        case .fire:   return .orange
        case .moon:   return .white
        case .water:  return .cyan
        case .rose:   return .pink
        }
    }
}

#Preview { NavigationStack { ReadingsLibraryView() } }
