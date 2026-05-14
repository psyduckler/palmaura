import SwiftUI

struct OnboardingView: View {
    @State private var answers = OnboardingAnswers.default
    @State private var step = 0
    @State private var showCapture = false
    @State private var birthMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var birthDay: Int = Calendar.current.component(.day, from: Date())
    @State private var birthYear = Calendar.current.component(.year, from: Date()) - 30

    private let totalSteps = 3

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 22) {
                ScreenHeader(
                    eyebrow: "PalmAura",
                    back: step > 0,
                    onBack: { withAnimation(.easeInOut(duration: 0.22)) { step = max(0, step - 1) } }
                )
                .padding(.horizontal, -24)

                VStack(alignment: .leading, spacing: 12) {
                    Text(currentStep.eyebrow)
                        .font(DesignSystem.FontToken.caps(10))
                        .tracking(DesignSystem.Tracking.caps)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                    Text(currentStep.title)
                        .font(DesignSystem.FontToken.display(44))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                        .minimumScaleFactor(0.72)
                    Text(currentStep.subtitle)
                        .font(DesignSystem.FontToken.body(18, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        switch step {
                        case 0: birthdayStep
                        case 1: genderStep
                        default: dominantHandStep
                        }
                    }
                    .padding(.vertical, 4)
                }

                GoldButton(title: step == totalSteps - 1 ? "Read My Palm ›" : "Continue ›") {
                    advanceOrFinish()
                }
                .opacity(canContinueCurrentStep ? 1 : 0.45)
                .disabled(!canContinueCurrentStep)

                StepPips(total: totalSteps, index: step)

                DisclaimerFoot()
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: preloadSavedPersonalization)
        .navigationDestination(isPresented: $showCapture) {
            PalmCaptureView(onboardingAnswers: answers)
        }
    }

    private var currentStep: OnboardingStepCopy {
        switch step {
        case 0:
            return OnboardingStepCopy(eyebrow: "Step 1 of 3", title: "When did you arrive?", subtitle: "Your full birthday keeps the reading age-aware and symbolically timed. Saved locally on this device.")
        case 1:
            return OnboardingStepCopy(eyebrow: "Step 2 of 3", title: "Choose your profile", subtitle: "Gender is used only as saved reading context. Pick what fits, or skip by preference.")
        default:
            return OnboardingStepCopy(eyebrow: "Step 3 of 3", title: "Your dominant hand", subtitle: "Dominant hands show active choices and the path you are shaping now.")
        }
    }

    private var birthdayStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Birthday")
                .font(DesignSystem.FontToken.caps(10))
                .tracking(DesignSystem.Tracking.caps)
                .foregroundStyle(DesignSystem.ColorToken.textTertiary)
            Text("Month, day, and year are required once. You can clear or edit them later in Settings.")
                .font(DesignSystem.FontToken.body(14))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)

            HStack(spacing: 12) {
                Picker("Month", selection: $birthMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthName(month)).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 150)
                .clipped()

                Picker("Day", selection: $birthDay) {
                    ForEach(1...maxDayForSelectedMonth, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 150)
                .clipped()
            }

            Picker("Year", selection: $birthYear) {
                ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxHeight: 130)
            .clipped()
        }
        .onAppear(perform: updateBirthdayContext)
        .onChange(of: birthMonth) { _, _ in normalizeBirthdaySelection() }
        .onChange(of: birthDay) { _, _ in updateBirthdayContext() }
        .onChange(of: birthYear) { _, _ in normalizeBirthdaySelection() }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.ColorToken.surfaceSoft)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg).stroke(DesignSystem.ColorToken.borderSoft, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
    }

    private var genderStep: some View {
        VStack(spacing: 12) {
            ForEach(Gender.allCases) { gender in
                OnboardingChoiceCard(title: gender.displayName, subtitle: gender.subtitle, icon: gender.icon, isSelected: answers.personalization?.gender == gender) {
                    ensurePersonalization()
                    answers.personalization?.gender = gender
                    advanceOrFinish()
                }
            }
        }
    }

    private var dominantHandStep: some View {
        VStack(spacing: 12) {
            ForEach(Handedness.allCases) { handedness in
                OnboardingChoiceCard(title: handedness.displayName, subtitle: handedness.subtitle, icon: handedness.icon, isSelected: answers.personalization?.handedness == handedness) {
                    ensurePersonalization()
                    answers.personalization?.handedness = handedness
                    advanceOrFinish()
                }
            }
        }
    }

    private var canContinueCurrentStep: Bool {
        switch step {
        case 0: return true
        case 1: return answers.personalization?.gender != nil
        default: return answers.personalization?.handedness != nil
        }
    }

    private var maxDayForSelectedMonth: Int {
        var components = DateComponents()
        components.year = birthYear
        components.month = birthMonth
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private func advanceOrFinish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateBirthdayContext()
        guard canContinueCurrentStep else { return }
        if step < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.25)) { step += 1 }
        } else {
            let personalization = answers.personalization?.withoutQuestion
            answers.personalization = personalization
            PersonalizationStore.save(personalization)
            Analytics.shared.track("onboarding_completed", properties: [
                "genderProvided": String(personalization?.gender != nil),
                "dominantHandProvided": String(personalization?.handedness != nil),
                "birthdayProvided": String(personalization?.birthDate != nil),
                "birthYearProvided": String(personalization?.birthDate != nil)
            ])
            showCapture = true
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
        Calendar.current.monthSymbols[month - 1]
    }
}

private struct OnboardingStepCopy {
    let eyebrow: String
    let title: String
    let subtitle: String
}

private struct OnboardingChoiceCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ChoiceCard(glyph: icon, title: title, subtitle: subtitle, selected: isSelected, action: action)
    }
}

private extension Gender {
    var icon: String {
        switch self {
        case .woman: return "♀"
        case .man: return "♂"
        case .nonBinary: return "✦"
        case .preferNotToSay: return "☽"
        }
    }

    var subtitle: String {
        switch self {
        case .woman: return "Saved locally as reading context."
        case .man: return "Saved locally as reading context."
        case .nonBinary: return "Saved locally as reading context."
        case .preferNotToSay: return "No gendered lens will be used."
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

    var subtitle: String {
        switch self {
        case .left: return "Your left hand is your active path."
        case .right: return "Your right hand is your active path."
        case .ambidextrous: return "Both hands share the active path."
        }
    }
}

#Preview { NavigationStack { OnboardingView() } }
