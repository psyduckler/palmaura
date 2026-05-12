import SwiftUI

@main
struct PalmAuraApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { Analytics.shared.track("app_opened") }
        }
    }
}
