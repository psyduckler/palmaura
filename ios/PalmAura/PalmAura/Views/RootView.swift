import SwiftUI

/// App-wide destinations used by the persistent top navigation.
private enum RootDestination: Hashable {
    case settings
}

extension Notification.Name {
    static let palmAuraNavigateHome = Notification.Name("palmAuraNavigateHome")
    static let palmAuraNavigateSettings = Notification.Name("palmAuraNavigateSettings")
}

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
    @State private var navigationPath = NavigationPath()
    @State private var navigationResetID = UUID()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            rootContent
                .navigationDestination(for: RootDestination.self) { destination in
                    switch destination {
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .id(navigationResetID)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .palmAuraNavigateHome)) { _ in
            navigateHome()
        }
        .onReceive(NotificationCenter.default.publisher(for: .palmAuraNavigateSettings)) { _ in
            navigateSettings()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
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

    private func navigateHome() {
        showOpening = false
        navigationPath = NavigationPath()
        navigationResetID = UUID()
    }

    private func navigateSettings() {
        showOpening = false
        var path = NavigationPath()
        path.append(RootDestination.settings)
        navigationPath = path
        navigationResetID = UUID()
    }
}

#Preview { RootView() }
