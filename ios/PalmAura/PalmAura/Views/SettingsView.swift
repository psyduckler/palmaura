import SwiftUI

/// Settings — reskinned to the same vintage-engraving design system as the rest
/// of the app. Preserves every existing destructive action and navigation
/// destination from the previous List-based implementation. Destructive actions
/// now confirm via .alert(...) before firing.
struct SettingsView: View {
    @State private var lastReading = LastReadingStore.load()
    @State private var savedPalmPhotoCount = PalmPhotoStore.count
    @State private var savedPersonalization = PersonalizationStore.load()

    @State private var pendingAction: PendingAction?

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Settings", back: true)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if let lastReading {
                            let bundle = ReadingBundle.restore(reading: lastReading)
                            lastReadingPanel(reading: lastReading, bundle: bundle)
                        }
                        profilePanel
                        photosPanel
                        privacyPanel
                        aboutPanel
                        DisclaimerFoot()
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, 6)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(item: $pendingAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.message),
                primaryButton: .destructive(Text(action.confirmTitle)) { action.run(); refreshAll() },
                secondaryButton: .cancel()
            )
        }
        .onAppear { refreshAll() }
    }

    // MARK: - Panels

    private func lastReadingPanel(reading: PalmReadingResponse, bundle: ReadingBundle) -> some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("YOUR LAST READING")
                VStack(alignment: .leading, spacing: 4) {
                    Text(reading.title)
                        .font(DesignSystem.FontToken.display(24))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text(reading.oneLineSummary)
                        .font(DesignSystem.FontToken.body(14, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .lineLimit(2)
                }

                VStack(spacing: 8) {
                    NavigationLink {
                        ReadingResultView(bundle: bundle)
                    } label: {
                        navRow(title: "Open Full Report")
                    }.buttonStyle(.plain)

                    if bundle.hasPhoto {
                        NavigationLink {
                            PalmMapView(bundle: bundle)
                        } label: {
                            navRow(title: "Open Palm Map")
                        }.buttonStyle(.plain)
                    }

                    Button {
                        pendingAction = .clearLastReading
                    } label: {
                        navRow(title: "Clear Last Reading", destructive: true)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var profilePanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("YOUR PROFILE")
                if let savedPersonalization, savedPersonalization.isCompleteProfile {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(profileLines(savedPersonalization), id: \.self) { line in
                            HStack(alignment: .top, spacing: 8) {
                                Text("✦")
                                    .font(DesignSystem.FontToken.display(11))
                                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
                                Text(line)
                                    .font(DesignSystem.FontToken.body(14))
                                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                            }
                        }
                    }
                    Button { pendingAction = .clearProfile } label: {
                        navRow(title: "Clear Saved Profile", destructive: true)
                    }.buttonStyle(.plain)
                } else {
                    Text("Your profile will be remembered after your first reading.")
                        .font(DesignSystem.FontToken.body(14, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                }
            }
        }
    }

    private var photosPanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("SAVED PALM PHOTOS")
                HStack {
                    Text("On this device")
                        .font(DesignSystem.FontToken.body(14))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    Spacer()
                    Text("\(savedPalmPhotoCount)")
                        .font(DesignSystem.FontToken.display(20))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                }
                if savedPalmPhotoCount > 0 {
                    Button { pendingAction = .deletePhotos } label: {
                        navRow(title: "Delete Saved Photos", destructive: true)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var privacyPanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("PRIVACY")
                Text("PalmAura sends your palm image only for the reading request. Saved palm photos stay on this device for reveal, palm-map browsing, and sharing.")
                    .font(DesignSystem.FontToken.body(13))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .lineSpacing(2)
                Text("Your one-time profile — birthday, gender, and dominant hand — is stored on this device and sent with reading requests for context. Free-form questions are not collected or saved.")
                    .font(DesignSystem.FontToken.body(13))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .lineSpacing(2)

                VStack(spacing: 6) {
                    Link(destination: URL(string: "\(BrandConfig.websiteURL)/privacy.html")!) {
                        navRow(title: "Privacy Policy", trailing: "↗")
                    }
                    Link(destination: URL(string: "\(BrandConfig.websiteURL)/terms.html")!) {
                        navRow(title: "Terms of Use", trailing: "↗")
                    }
                }
            }
        }
    }

    private var aboutPanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("ABOUT")
                HStack {
                    Text("Version")
                        .font(DesignSystem.FontToken.body(14))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")
                        .font(DesignSystem.FontToken.body(14))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                }
                Text(BrandConfig.entertainmentDisclaimer)
                    .font(DesignSystem.FontToken.body(12, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Building blocks

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.FontToken.caps(9))
            .tracking(DesignSystem.Tracking.caps)
            .foregroundStyle(DesignSystem.ColorToken.textTertiary)
    }

    private func navRow(title: String, trailing: String = "›", destructive: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(DesignSystem.FontToken.caps(10))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundStyle(destructive
                    ? DesignSystem.ColorToken.goldCream.opacity(0.55)
                    : DesignSystem.ColorToken.goldCream.opacity(0.86))
            Spacer()
            Text(trailing)
                .font(DesignSystem.FontToken.display(15))
                .foregroundStyle(destructive
                    ? DesignSystem.ColorToken.goldCream.opacity(0.45)
                    : DesignSystem.ColorToken.goldCream.opacity(0.7))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            Capsule().stroke(
                destructive
                    ? DesignSystem.ColorToken.goldCream.opacity(0.20)
                    : DesignSystem.ColorToken.goldCream.opacity(0.32),
                lineWidth: 1
            )
        )
    }

    // MARK: - Data

    private func profileLines(_ p: ReadingPersonalization) -> [String] {
        var parts: [String] = []
        if let birthDate = p.birthDate {
            let month = Calendar.current.monthSymbols[max(0, min(11, birthDate.month - 1))]
            parts.append("Birthday: \(month) \(birthDate.day), \(birthDate.year)")
        }
        if let gender = p.gender { parts.append("Gender: \(gender.displayName)") }
        if let handedness = p.handedness { parts.append("Dominant hand: \(handedness.displayName)") }
        return parts.isEmpty ? ["No saved personalization"] : parts
    }

    private func refreshAll() {
        lastReading = LastReadingStore.load()
        savedPalmPhotoCount = PalmPhotoStore.count
        savedPersonalization = PersonalizationStore.load()
    }
}

// MARK: - Pending destructive actions

private enum PendingAction: Identifiable {
    case clearLastReading
    case clearProfile
    case deletePhotos

    var id: String {
        switch self {
        case .clearLastReading: return "clearLastReading"
        case .clearProfile: return "clearProfile"
        case .deletePhotos: return "deletePhotos"
        }
    }

    var title: String {
        switch self {
        case .clearLastReading: return "Clear last reading?"
        case .clearProfile: return "Clear saved profile?"
        case .deletePhotos: return "Delete saved palm photos?"
        }
    }

    var message: String {
        switch self {
        case .clearLastReading: return "This removes your stored reading from this device. You can always get a new one."
        case .clearProfile: return "This removes your birthday, gender, and dominant hand from this device. You'll be asked again for your next reading."
        case .deletePhotos: return "Saved palm photos on this device will be permanently removed."
        }
    }

    var confirmTitle: String {
        switch self {
        case .clearLastReading: return "Clear Reading"
        case .clearProfile: return "Clear Profile"
        case .deletePhotos: return "Delete Photos"
        }
    }

    func run() {
        switch self {
        case .clearLastReading: LastReadingStore.clear()
        case .clearProfile: PersonalizationStore.clear()
        case .deletePhotos: PalmPhotoStore.clearAll()
        }
    }
}

#Preview { NavigationStack { SettingsView() } }
