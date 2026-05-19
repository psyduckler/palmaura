import SwiftUI

/// App-wide destinations used by the persistent top navigation.
private enum RootDestination: Hashable {
    case settings
}

/// Centralized navigation state. Owned by `RootView` as a `@StateObject` and
/// exposed to nested views (notably `ScreenHeader`) via an environment value.
/// This replaces the earlier pattern of posting `NotificationCenter` events
/// and force-rebuilding the entire NavigationStack with a UUID `.id(...)`.
///
/// Navigation behaviour:
/// - `goHome()` empties the navigation path so the `NavigationStack` returns
///   to its root content (whichever screen `RootView.rootContent` resolves to
///   based on the disclaimer / profile gates).
/// - `goSettings()` resets the path to `[.settings]`, pushing Settings as the
///   single top entry. Tapping Settings from inside Settings is a no-op
///   reset.
@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func goHome() {
        path = NavigationPath()
    }

    func goSettings() {
        var newPath = NavigationPath()
        newPath.append(RootDestination.settings)
        path = newPath
    }
}

/// Environment key so `ScreenHeader` (and any future nested view) can reach
/// the coordinator without an `@EnvironmentObject` requirement. Default is
/// `nil` so SwiftUI previews don't crash when the coordinator isn't injected
/// — navigation calls become no-ops in that case, which is the desired
/// preview behaviour.
private struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue: NavigationCoordinator? = nil
}

extension EnvironmentValues {
    var navigationCoordinator: NavigationCoordinator? {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}

/// Top-level navigation gate.
///
/// Flow:
///   1. `AppOpeningView` plays the 3.2s splash (OrbitLoader + cycling salutations).
///   2. If the user hasn't accepted the entertainment disclaimer yet, show it.
///   3. If the one-time profile is incomplete, collect it.
///   4. Otherwise drop into `HomeView`.
///
/// `showOpening` is local state — the splash plays once per process launch,
/// not once per install — matches the design canvas behavior. The persistent
/// global nav is hidden during splash, disclaimer, and first-run onboarding
/// (see `ScreenHeader.compact`), so nav events cannot fire before
/// `showOpening` flips on its own.
struct RootView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false
    @AppStorage(PersonalizationStore.completionKey) private var profileCompleted = false
    @State private var showOpening = true
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            rootContent
                .navigationDestination(for: RootDestination.self) { destination in
                    switch destination {
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environment(\.navigationCoordinator, coordinator)
        .preferredColorScheme(.dark)
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
}

#Preview { RootView() }
