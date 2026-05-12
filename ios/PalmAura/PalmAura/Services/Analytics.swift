import Foundation

final class Analytics {
    static let shared = Analytics()
    private init() {}

    func track(_ name: String, properties: [String: String] = [:]) {
        #if DEBUG
        print("Analytics", name, properties)
        #endif
    }
}
