import SwiftUI

/// Completion behavior for the one-time profile screen.
enum ProfileCompletionDestination { case home, dismiss }

/// One-time profile onboarding. It collects durable calibration only; the
/// per-reading question lives in `ReadingQuestionView`.
struct OnboardingView: View {
    var completionDestination: ProfileCompletionDestination = .home
    @Environment(\.dismiss) private var dismiss
    @State private var answers = OnboardingAnswers.default
    @State private var birthMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var birthDay: Int = Calendar.current.component(.day, from: Date())
    @State private var birthYear = Calendar.current.component(.year, from: Date()) - 30
    @State private var showHome = false

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ScreenHeader(eyebrow: "Profile")
                        .padding(.horizontal, -24)

                    intro

                    section(numeral: "I",
                            eyebrow: "FOR YOUR COSMIC SEASON",
                            title: "When did you arrive?",
                            rationale: "Your sun sign and life rhythm anchor the reading to the season you were born into.") {
                        birthdayPickers
                    }

                    section(numeral: "II",
                            eyebrow: "FOR THE CURRENT YOU CARRY",
                            title: "How do you carry your energy?",
                            rationale: "Different currents pass through the hand. We use this only to shape the voice.") {
                        genderGrid
                    }

                    section(numeral: "III",
                            eyebrow: "FOR YOUR ACTIVE PATH",
                            title: "Which is your dominant hand?",
                            rationale: "Your dominant hand carries your active path. The other holds older patterns.") {
                        handednessGrid
                    }

                    privacyFootnote

                    GoldButton(title: "Save Profile  ›") { advanceOrFinish() }
                        .opacity(canContinue ? 1 : 0.45)
                        .disabled(!canContinue)

                    Text("ONE TIME ONLY · THEN ASK ONE QUESTION")
                        .font(DesignSystem.FontToken.caps(8.5))
                        .tracking(2.5)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.45))

                    DisclaimerFoot()
                }
                .padding(24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: preloadSavedPersonalization)
        .navigationDestination(isPresented: $showHome) {
            HomeView()
        }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: 8) {
            Text("·  BEFORE THE LINES SPEAK  ·")
                .font(DesignSystem.FontToken.caps(10))
                .tracking(DesignSystem.Tracking.caps)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.7))

            VStack(spacing: 2) {
                Text("One profile,")
                    .font(DesignSystem.FontToken.display(34))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text("then the question.")
                    .font(DesignSystem.FontToken.display(34, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream)
            }
            .multilineTextAlignment(.center)

            Text("These durable details calibrate every reading. After this, each scan asks only the fresh question for that moment.")
                .font(DesignSystem.FontToken.body(15, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section primitive

    @ViewBuilder
    private func section<Content: View>(numeral: String, eyebrow: String, title: String, rationale: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(numeral).")
                    .font(DesignSystem.FontToken.display(18, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.6))
                Text(eyebrow)
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(DesignSystem.Tracking.caps)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
            }

            Text(title)
                .font(DesignSystem.FontToken.display(24))
                .foregroundStyle(DesignSystem.ColorToken.textPrimary)

            Text(rationale)
                .font(DesignSystem.FontToken.body(13, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .lineSpacing(2)

            content()
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.ColorToken.surfaceSoft)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }

    // MARK: - Birthday (Section I)

    private var birthdayPickers: some View {
        HStack(spacing: 8) {
            pickerCell(label: "MONTH", value: monthName(birthMonth)) {
                Picker("Month", selection: $birthMonth) {
                    ForEach(1...12, id: \.self) { Text(monthName($0)).tag($0) }
                }
            }
            pickerCell(label: "DAY", value: "\(birthDay)") {
                Picker("Day", selection: $birthDay) {
                    ForEach(1...maxDayForSelectedMonth, id: \.self) { Text("\($0)").tag($0) }
                }
            }
            pickerCell(label: "YEAR", value: "\(birthYear)") {
                Picker("Year", selection: $birthYear) {
                    ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) {
                        Text("\($0)").tag($0)
                    }
                }
            }
        }
        .onAppear(perform: updateBirthdayContext)
        .onChange(of: birthMonth) { _, _ in normalizeBirthdaySelection() }
        .onChange(of: birthDay) { _, _ in updateBirthdayContext() }
        .onChange(of: birthYear) { _, _ in normalizeBirthdaySelection() }
    }

    private func pickerCell<P: View>(label: String, value: String, @ViewBuilder picker: () -> P) -> some View {
        Menu {
            picker().pickerStyle(.inline)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignSystem.FontToken.caps(7.5))
                    .tracking(1.8)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.55))
                Text(value)
                    .font(DesignSystem.FontToken.display(18))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(DesignSystem.ColorToken.goldCream.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gender (Section II)

    private var genderGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Gender.allCases) { gender in
                GlyphChip(
                    glyph: gender.icon,
                    title: gender.displayName,
                    subtitle: nil,
                    selected: answers.personalization?.gender == gender
                ) {
                    ensurePersonalization()
                    answers.personalization?.gender = gender
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    // MARK: - Dominant hand (Section III)

    private var handednessGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Handedness.allCases) { hand in
                GlyphChip(
                    glyph: hand.icon,
                    title: hand.shortTitle,
                    subtitle: hand.poeticLabel,
                    selected: answers.personalization?.handedness == hand
                ) {
                    ensurePersonalization()
                    answers.personalization?.handedness = hand
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    // MARK: - Privacy footnote

    private var privacyFootnote: some View {
        HStack(spacing: 10) {
            Text("🜍")
                .font(DesignSystem.FontToken.display(18))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.75))
            Text("Saved only on your device. These answers shape future readings, but your per-reading question stays separate.")
                .font(DesignSystem.FontToken.body(12.5, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.22), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Validation

    private var canContinue: Bool {
        answers.personalization?.gender != nil &&
        answers.personalization?.handedness != nil
    }

    private var maxDayForSelectedMonth: Int {
        var components = DateComponents()
        components.year = birthYear
        components.month = birthMonth
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    // MARK: - State helpers

    private func advanceOrFinish() {
        guard canContinue else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateBirthdayContext()
        let personalization = answers.personalization?.withoutQuestion
        answers.personalization = personalization
        PersonalizationStore.save(personalization)
        Analytics.shared.track("onboarding_completed", properties: [
            "genderProvided": String(personalization?.gender != nil),
            "dominantHandProvided": String(personalization?.handedness != nil),
            "birthdayProvided": String(personalization?.birthDate != nil),
            "birthYearProvided": String(personalization?.birthDate != nil),
            "combinedScreen": "true"
        ])
        switch completionDestination {
        case .home:
            showHome = true
        case .dismiss:
            dismiss()
        }
    }

    private func preloadSavedPersonalization() {
        guard let saved = PersonalizationStore.load() else {
            ensurePersonalization()
            updateBirthdayContext()
            return
        }
        answers.personalization = saved.withoutQuestion
        if let birthDate = saved.birthDate {
            birthMonth = birthDate.month
            birthDay = birthDate.day
            birthYear = birthDate.year
        }
        updateBirthdayContext()
    }

    private func ensurePersonalization() {
        if answers.personalization == nil { answers.personalization = ReadingPersonalization() }
    }

    private func normalizeBirthdaySelection() {
        if birthDay > maxDayForSelectedMonth { birthDay = maxDayForSelectedMonth }
        updateBirthdayContext()
    }

    private func updateBirthdayContext() {
        ensurePersonalization()
        answers.personalization?.birthDate = BirthDateContext(month: birthMonth, day: birthDay, year: birthYear)
    }

    private func monthName(_ month: Int) -> String {
        Calendar.current.shortMonthSymbols[month - 1]
    }
}

// MARK: - GlyphChip (compact glyph + title + optional subtitle)

private struct GlyphChip: View {
    let glyph: String
    let title: String
    let subtitle: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(glyph)
                    .font(DesignSystem.FontToken.display(22))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream)
                Text(title)
                    .font(DesignSystem.FontToken.display(14))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(DesignSystem.FontToken.body(11, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: subtitle != nil ? 86 : 70)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.16 : 0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.7 : 0.22), lineWidth: 1)
            )
            .shadow(color: DesignSystem.ColorToken.goldCream.opacity(selected ? 0.18 : 0), radius: 18)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gender + Handedness glyph/subtitle helpers (private to this file)

private extension Gender {
    var icon: String {
        switch self {
        case .woman: return "♀"
        case .man: return "♂"
        case .nonBinary: return "☿"
        case .preferNotToSay: return "✦"
        }
    }
}

private extension Handedness {
    var icon: String {
        switch self {
        case .left: return "☽"
        case .right: return "☉"
        case .ambidextrous: return "☿"
        }
    }
    /// Short single-word title (the existing `displayName` is "Left-handed"
    /// which is too long for a 3-up chip grid).
    var shortTitle: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .ambidextrous: return "Both"
        }
    }
    var poeticLabel: String {
        switch self {
        case .left: return "the moon-side"
        case .right: return "the sun-side"
        case .ambidextrous: return "both currents"
        }
    }
}

#Preview { NavigationStack { OnboardingView() } }
