import Foundation

enum PalmLineSetStore {
    private static let prefix = "palmLines_"

    static func save(_ lineSet: PalmLineSet, for readingId: String) {
        guard let data = try? JSONEncoder().encode(lineSet) else { return }
        UserDefaults.standard.set(data, forKey: key(readingId))
    }

    static func load(for readingId: String) -> PalmLineSet? {
        guard let data = UserDefaults.standard.data(forKey: key(readingId)) else { return nil }
        return try? JSONDecoder().decode(PalmLineSet.self, from: data)
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
