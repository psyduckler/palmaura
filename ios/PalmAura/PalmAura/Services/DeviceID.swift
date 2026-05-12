import UIKit

enum DeviceID {
    static var current: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
}
