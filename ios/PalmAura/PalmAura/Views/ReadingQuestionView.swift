import SwiftUI

/// Per-reading intent screen. Durable profile context stays in `PersonalizationStore`;
/// this screen only captures the focus/question for the next scan.
struct ReadingQuestionView: View {
    /// Optional pre-selected focus, e.g. when the user lands here from a
    /// HomeView focus chip. Defaults to the first option (Relationship).
    var initialFocus: ReadingFocus = .love

    @State private var selectedOption: SessionFocusOption
    @State private var questionText: String = ""
    @State private var showCapture = false
    @State private var skipQuestion = false
    @State private var showQuestionEditor = false
    @State private var profile = PersonalizationStore.load()
    @FocusState private var questionFocused: Bool

    init(initialFocus: ReadingFocus = .love) {
        self.initialFocus = initialFocus
        let option = SessionFocusOption.option(matching: initialFocus)
        _selectedOption = State(initialValue: option)
        _showQuestionEditor = State(initialValue: option.isBespoke)
    }

    private var hasProfile: Bool { profile?.isCompleteProfile == true }

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ScreenHeader(eyebrow: "", back: true)
                        .padding(.horizontal, -DesignSystem.Spacing.lg)

                    if hasProfile {
                        intro
                        focusGrid
                        if showQuestionEditor {
                            questionBox
                            privacyNote
                        }
                        actionStack
                    } else {
                        missingProfileCard
                    }

                    DisclaimerFoot()
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .onAppear { profile = PersonalizationStore.load() }
        .navigationDestination(isPresented: $showCapture) {
            PalmCaptureView(onboardingAnswers: buildAnswers())
        }
    }

    private var intro: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("What should the palm")
                    .font(DesignSystem.FontToken.display(34))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text("look into?")
                    .font(DesignSystem.FontToken.display(36, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.goldCream)
            }
            .multilineTextAlignment(.center)

            Text("One question for this moment. Your birthday, gender, and dominant hand stay in your saved profile.")
                .font(DesignSystem.FontToken.body(15, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var focusGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 104), spacing: 9)]
        return LazyVGrid(columns: columns, spacing: 9) {
            ForEach(SessionFocusOption.all) { option in
                Button {
                    withAnimation(.snappy(duration: 0.24)) {
                        selectedOption = option
                        showQuestionEditor = option.isBespoke
                    }
                    if !option.isBespoke { questionFocused = false }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 6) {
                        Text(option.glyph)
                            .font(DesignSystem.FontToken.display(24))
                        Text(option.title)
                            .font(DesignSystem.FontToken.caps(9))
                            .tracking(2.2)
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(option == selectedOption ? DesignSystem.ColorToken.skyDeep : DesignSystem.ColorToken.goldCream.opacity(0.9))
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(option == selectedOption ? DesignSystem.ColorToken.goldCream.opacity(0.92) : DesignSystem.ColorToken.goldCream.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(DesignSystem.ColorToken.goldCream.opacity(option == selectedOption ? 0.85 : 0.26), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var questionBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Text(selectedOption.glyph)
                        .font(DesignSystem.FontToken.display(18))
                        .accessibilityHidden(true)
                    Text("Bespoke question")
                        .font(DesignSystem.FontToken.caps(9))
                        .tracking(2.4)
                        .textCase(.uppercase)
                }
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.86))

                Spacer()

                Text("MAX 200")
                    .font(DesignSystem.FontToken.caps(7.5))
                    .tracking(1.6)
                    .foregroundStyle(DesignSystem.ColorToken.textTertiary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $questionText)
                    .font(DesignSystem.FontToken.body(17, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($questionFocused)
                    .frame(minHeight: 112)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)

                if questionText.isEmpty && !questionFocused {
                    Text(selectedOption.suggestedQuestion)
                        .font(DesignSystem.FontToken.body(17, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 112)
            .background(DesignSystem.ColorToken.goldCream.opacity(0.065))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DesignSystem.ColorToken.goldCream.opacity(questionFocused ? 0.65 : 0.28), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onTapGesture { questionFocused = true }
            .onChange(of: questionText) { _, newValue in
                if newValue.count > 200 { questionText = String(newValue.prefix(200)) }
            }
        }
        .padding(16)
        .background(DesignSystem.ColorToken.surfaceSoft)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.async { questionFocused = true }
        }
        .onDisappear {
            questionFocused = false
        }
    }

    private var privacyNote: some View {
        HStack(spacing: 10) {
            Text("✦")
                .font(DesignSystem.FontToken.display(18))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                .accessibilityHidden(true)
            Text("This question travels with the next reading only. It is not saved to your profile.")
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

    private var actionStack: some View {
        VStack(spacing: 12) {
            GoldButton(title: "Open My Palm  ›") {
                beginReading(skip: false)
            }
        }
    }

    private var missingProfileCard: some View {
        ParchmentPanel {
            VStack(spacing: 14) {
                GlyphCircle(glyph: "☉", size: 52, selected: true)
                Text("Profile first.")
                    .font(DesignSystem.FontToken.display(30))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text("PalmAura needs your one-time birthday, gender, and dominant hand before a reading. Then every future reading starts here.")
                    .font(DesignSystem.FontToken.body(15, italic: true))
                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                NavigationLink { OnboardingView() } label: {
                    Text("Complete Profile  ›")
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
            }
        }
    }

    private func beginReading(skip: Bool) {
        skipQuestion = skip
        questionFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Analytics.shared.track("reading_question_completed", properties: [
            "focus": selectedOption.title,
            "questionProvided": String(!trimmedQuestion(skip: skip).isEmpty),
            "skipped": String(skip)
        ])
        showCapture = true
    }

    private func buildAnswers() -> OnboardingAnswers {
        var answers = OnboardingAnswers.forSavedProfile()
        answers.focus = selectedOption.backendFocus
        answers.lifeSeason = selectedOption.lifeSeason
        answers.readingStyle = .mysterious

        var personalization = (PersonalizationStore.load() ?? ReadingPersonalization()).withoutQuestion
        personalization.timeZoneIdentifier = TimeZone.current.identifier
        personalization.localeRegionCode = Locale.current.region?.identifier
        let question = trimmedQuestion(skip: skipQuestion)
        personalization.question = question.isEmpty ? nil : question
        answers.personalization = personalization
        answers.sessionIntent = ReadingSessionIntent(focus: selectedOption.title, question: question.isEmpty ? nil : question)
        return answers
    }

    private func trimmedQuestion(skip: Bool) -> String {
        guard !skip, selectedOption.isBespoke else { return "" }
        return questionText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct SessionFocusOption: Identifiable, Equatable {
    let id: String
    let title: String
    let glyph: String
    let suggestedQuestion: String
    let backendFocus: ReadingFocus
    let lifeSeason: LifeSeason

    static let relationship = SessionFocusOption(
        id: "relationship",
        title: "Relationship",
        glyph: "♀",
        suggestedQuestion: "What should I understand about this relationship?",
        backendFocus: .love,
        lifeSeason: .bigDecision
    )

    static let all: [SessionFocusOption] = [
        relationship,
        .init(id: "career", title: "Career", glyph: "♄", suggestedQuestion: "What should I know about the path my work is taking?", backendFocus: .career, lifeSeason: .buildingMomentum),
        .init(id: "money", title: "Money", glyph: "♃", suggestedQuestion: "What pattern around money is asking for my attention?", backendFocus: .money, lifeSeason: .bigDecision),
        .init(id: "family", title: "Family", glyph: "☽", suggestedQuestion: "What should I see more clearly in my family life?", backendFocus: .family, lifeSeason: .healing),
        .init(id: "the_path", title: "The path", glyph: "✦", suggestedQuestion: "What is the next right step on my path?", backendFocus: .purpose, lifeSeason: .unknown),
        .init(id: "bespoke", title: "Bespoke", glyph: "✦", suggestedQuestion: "What specific question should this reading answer?", backendFocus: .general, lifeSeason: .unknown)
    ]

    var isBespoke: Bool { id == "bespoke" }

    /// Look up the focus option whose backend enum matches the given
    /// `ReadingFocus`. Falls back to `.relationship` if no exact match
    /// (e.g. `.general`, which isn't a focus chip).
    static func option(matching focus: ReadingFocus) -> SessionFocusOption {
        all.first(where: { $0.backendFocus == focus }) ?? .relationship
    }
}

#Preview { NavigationStack { ReadingQuestionView() } }
