import SwiftUI

/// Top-level navigation gate.
///
/// Flow:
///   1. `AppOpeningView` plays the 3.2s splash (OrbitLoader + cycling salutations).
///   2. If the user hasn't accepted the entertainment disclaimer yet, show it.
///   3. If the one-time profile is incomplete, collect it.
///   4. Otherwise drop into `HomeView`.
///
/// `showOpening` is local state — the splash plays once per process launch, not
/// once per install — matches the design canvas behavior.
struct RootView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false
    @AppStorage(PersonalizationStore.completionKey) private var profileCompleted = false
    @State private var showOpening = true

    var body: some View {
        NavigationStack {
            if showOpening {
                AppOpeningView { showOpening = false }
            } else if !disclaimerAccepted {
                DisclaimerView()
            } else if profileCompleted || PersonalizationStore.hasCompleteProfile() {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview { RootView() }
