import SwiftUI

struct OnboardingView: View {
    @State private var answers = OnboardingAnswers.default

    var body: some View {
        ZStack {
            MysticalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Begin the ritual")
                        .font(.custom("Georgia", size: 42).weight(.bold))
                    Text("Three quick choices help shape the tone of your symbolic reading.")
                        .foregroundStyle(.white.opacity(0.75))
                    section("What are you seeking clarity on?", ReadingFocus.allCases, selection: $answers.focus)
                    section("What season are you in?", LifeSeason.allCases.filter { $0 != .unknown }, selection: $answers.lifeSeason)
                    section("Choose your reading style.", ReadingStyle.allCases, selection: $answers.readingStyle)
                    NavigationLink { PalmCaptureView(onboardingAnswers: answers) } label: { Text("Continue") }
                        .buttonStyle(.borderedProminent)
                    NavigationLink { PalmCaptureView(onboardingAnswers: .default) } label: {
                        Text("Skip — read my palm").frame(maxWidth: .infinity)
                    }
                    .simultaneousGesture(TapGesture().onEnded { Analytics.shared.track("onboarding_skipped") })
                    DisclaimerFooter()
                }
                .padding(24)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func section<T: Identifiable & Hashable>(_ title: String, _ options: [T], selection: Binding<T>) -> some View where T: DisplayNamed {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            FlowLayout(options: options, selection: selection)
        }
    }
}

protocol DisplayNamed { var displayName: String { get } }
extension ReadingFocus: DisplayNamed {}
extension LifeSeason: DisplayNamed {}
extension ReadingStyle: DisplayNamed {}

struct FlowLayout<T: Identifiable & Hashable & DisplayNamed>: View {
    let options: [T]
    @Binding var selection: T
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(options) { option in
                QuestionChip(title: option.displayName, isSelected: option == selection) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selection = option
                }
            }
        }
    }
}
