import SwiftUI

struct RootView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false

    var body: some View {
        NavigationStack {
            if disclaimerAccepted {
                OnboardingView()
            } else {
                DisclaimerView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview { RootView() }
