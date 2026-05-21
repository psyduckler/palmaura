import SwiftUI

@main
struct PalmAuraApp: App {
    init() {
        // Order matters: migrate any legacy single-slot reading into the
        // file-backed history *before* the first prune, otherwise a
        // legacy reading with a stale createdAt could be pruned before
        // it has a chance to exist alongside newer entries.
        ReadingHistoryStore.migrateFromLastReadingIfNeeded()
        ReadingHistoryStore.prune()
        // Photo retention aligned with reading retention so photos for
        // pruned readings get reaped too.
        PalmPhotoStore.prune(keepMostRecent: ReadingHistoryStore.maxReadings)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { Analytics.shared.track("app_opened") }
        }
    }
}
