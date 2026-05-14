import Foundation

enum LastReadingStore {
    private static let key = "lastReading"

    static func save(_ reading: PalmReadingResponse) {
        guard let data = try? JSONEncoder().encode(reading) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> PalmReadingResponse? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PalmReadingResponse.self, from: data)
    }

    static func clear() {
        if let reading = load() { PalmLineSetStore.clear(for: reading.readingId) }
        UserDefaults.standard.removeObject(forKey: key)
    }
}
