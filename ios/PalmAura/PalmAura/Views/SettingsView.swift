import SwiftUI

struct SettingsView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = true
    @State private var personalization = PersonalizationStore.load() ?? ReadingPersonalization()
    @State private var lunarRemindersOn = true
    @State private var showResetAlert = false
    @State private var showClearHistoryAlert = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView {
                VStack(spacing: 22) {
                    ScreenHeader(eyebrow: "Settings", moon: false, back: true)
                        .padding(.horizontal, -DesignSystem.Spacing.lg)

                    profileCard
                    section(title: "READING") {
                        row(glyph: "☉", label: "Oracle voice",        detail: voiceDetail)
                        row(glyph: "♀", label: "Question focus",      detail: "Asked each reading")
                        toggleRow(glyph: "☽", label: "Lunar reminders", isOn: $lunarRemindersOn)
                    }
                    section(title: "PERSONALIZATION") {
                        row(glyph: "♃", label: "Birthday",       detail: birthdayDetail)
                        row(glyph: "✦", label: "Energy",         detail: personalization.gender?.displayName ?? "Not set")
                        row(glyph: "☉", label: "Dominant hand",  detail: personalization.handedness?.displayName ?? "Not set")
                        row(glyph: "⌖", label: "Location",       detail: locationDetail)
                        navRow(glyph: "☽", label: "Edit profile") { showEditProfile = true }
                    }
                    section(title: "KEEPSAKES") {
                        navRow(glyph: "✦", label: "Library of readings") { /* TODO: ReadingsLibraryView */ }
                    }
                    section(title: "ACCOUNT") {
                        row(glyph: "♃", label: "Membership", detail: "Lifetime")
                        linkRow(glyph: "✉", label: "Support", url: URL(string: "mailto:support@palmaura.app")!)
                        linkRow(glyph: "♄", label: "Privacy & terms", url: URL(string: "https://palmaura.app/privacy.html")!)
                    }

                    aboutCard
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showEditProfile) {
            OnboardingView(completionDestination: .dismiss)
        }
        .onAppear { personalization = PersonalizationStore.load() ?? ReadingPersonalization() }
        .alert("Reset all personalization?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                PersonalizationStore.clear()
                personalization = ReadingPersonalization()
            }
        } message: {
            Text("Your birthday, energy, dominant hand, and location override will be cleared. The app will ask again on your next reading.")
        }
        .alert("Clear reading history?", isPresented: $showClearHistoryAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                LastReadingStore.clear()
                PalmPhotoStore.clearAll()
                ReadingIntentStore.clearAll()
            }
        } message: {
            Text("Your saved reading, palm photo, line map, and session question history will be cleared from this device.")
        }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(RadialGradient(
                    colors: [DesignSystem.ColorToken.goldCreamSoft, DesignSystem.ColorToken.gold],
                    center: .topLeading, startRadius: 5, endRadius: 56))
                Text(initialChar)
                    .font(DesignSystem.FontToken.display(26))
                    .foregroundStyle(DesignSystem.ColorToken.skyDeep)
            }
            .frame(width: 56, height: 56)
            .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.4), radius: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text("Seeker")
                    .font(DesignSystem.FontToken.display(22))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text(profileSubtitle)
                    .font(DesignSystem.FontToken.body(13, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }

    // MARK: - About card

    private var aboutCard: some View {
        VStack(spacing: 12) {
            OrnamentRule()
            Text(BrandConfig.entertainmentDisclaimer)
                .font(DesignSystem.FontToken.body(13, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Text("Reset Profile")
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.7))
            }
            .padding(.top, 6)
            Button(role: .destructive) {
                showClearHistoryAlert = true
            } label: {
                Text("Clear Reading History")
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.7))
            }
            .padding(.top, 2)
            Text(versionString)
                .font(DesignSystem.FontToken.caps(8))
                .tracking(3)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.45))
        }
        .padding(18)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.045))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }

    // MARK: - Section primitive

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text("·").font(DesignSystem.FontToken.caps(11)).foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.6))
                Text(title)
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(DesignSystem.Tracking.caps)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.65))
                Text("·").font(DesignSystem.FontToken.caps(11)).foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.6))
            }
            .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(DesignSystem.ColorToken.goldCream.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                        .stroke(DesignSystem.ColorToken.goldCream.opacity(0.16), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
        }
    }

    // MARK: - Rows

    private func row(glyph: String, label: String, detail: String) -> some View {
        rowChrome(glyph: glyph) {
            Text(label).font(DesignSystem.FontToken.display(16)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
            Spacer()
            Text(detail).font(DesignSystem.FontToken.body(13, italic: true)).foregroundStyle(DesignSystem.ColorToken.textSecondary)
            chevron
        }
    }

    private func navRow(glyph: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowChrome(glyph: glyph) {
                Text(label).font(DesignSystem.FontToken.display(16)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Spacer()
                chevron
            }
        }.buttonStyle(.plain)
    }

    private func linkRow(glyph: String, label: String, url: URL) -> some View {
        Link(destination: url) {
            rowChrome(glyph: glyph) {
                Text(label).font(DesignSystem.FontToken.display(16)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Spacer()
                chevron
            }
        }
    }

    private func toggleRow(glyph: String, label: String, isOn: Binding<Bool>) -> some View {
        rowChrome(glyph: glyph) {
            Text(label).font(DesignSystem.FontToken.display(16)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(DesignSystem.ColorToken.goldCream)
        }
    }

    @ViewBuilder
    private func rowChrome<Content: View>(glyph: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            GlyphCircle(glyph: glyph, size: 30)
            content()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .overlay(Divider().background(DesignSystem.ColorToken.goldCream.opacity(0.1)), alignment: .bottom)
    }

    private var chevron: some View {
        Text("›")
            .font(DesignSystem.FontToken.display(18))
            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
    }

    // MARK: - Derived

    private var initialChar: String { "✦" }

    private var profileSubtitle: String {
        let readingsCount = LastReadingStore.load() != nil ? "1 reading" : "0 readings"
        let lean = personalization.gender?.displayName ?? "—"
        return "\(readingsCount) · \(lean) energy"
    }

    private var voiceDetail: String { "Mysterious" }

    private var birthdayDetail: String {
        guard let d = personalization.birthDate else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let components = DateComponents(year: d.year, month: d.month, day: d.day)
        let date = Calendar.current.date(from: components) ?? Date()
        return "\(formatter.string(from: date)), \(d.year)"
    }

    private var locationDetail: String {
        if let override = personalization.normalizedLocationOverride { return override }
        if let timeZone = personalization.timeZoneIdentifier, !timeZone.isEmpty { return "Auto · \(timeZone)" }
        return "Auto · \(TimeZone.current.identifier)"
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "PALMAURA · MMXXVI · v\(v)"
    }
}

#Preview { NavigationStack { SettingsView() } }
