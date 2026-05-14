import SwiftUI

@main
struct PalmAuraApp: App {
    init() {
        PalmPhotoStore.prune(keepMostRecent: 12)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { Analytics.shared.track("app_opened") }
        }
    }
}
