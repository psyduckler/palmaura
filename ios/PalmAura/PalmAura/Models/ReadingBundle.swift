import Foundation

struct ReadingBundle: Equatable {
    let reading: PalmReadingResponse
    let photoURL: URL?
    let auraColor: AuraColor
    let sessionIntent: ReadingSessionIntent?

    init(reading: PalmReadingResponse, photoURL: URL?, sessionIntent: ReadingSessionIntent? = nil) {
        self.reading = reading
        self.photoURL = photoURL
        self.auraColor = reading.auraColor
        self.sessionIntent = sessionIntent ?? ReadingIntentStore.load(for: reading.readingId)
    }

    static func restore(reading: PalmReadingResponse) -> ReadingBundle {
        ReadingBundle(
            reading: reading,
            photoURL: PalmPhotoStore.url(for: reading.readingId),
            sessionIntent: ReadingIntentStore.load(for: reading.readingId)
        )
    }

    var hasPhoto: Bool {
        guard let photoURL else { return false }
        return FileManager.default.fileExists(atPath: photoURL.path)
    }
}

enum ReadingIntentStore {
    private static let prefix = "palmaura.readingIntent."

    static func save(_ intent: ReadingSessionIntent?, for readingId: String) {
        guard let intent else { return }
        guard let data = try? JSONEncoder().encode(intent) else { return }
        UserDefaults.standard.set(data, forKey: key(readingId))
    }

    static func load(for readingId: String) -> ReadingSessionIntent? {
        guard let data = UserDefaults.standard.data(forKey: key(readingId)) else { return nil }
        return try? JSONDecoder().decode(ReadingSessionIntent.self, from: data)
    }

    static func clear(for readingId: String) {
        UserDefaults.standard.removeObject(forKey: key(readingId))
    }

    static func clearAll() {
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func key(_ readingId: String) -> String { prefix + readingId }
}
