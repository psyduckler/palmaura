import Foundation
import UIKit

enum PalmPhotoStore {
    static let pendingKey = "pending"

    static func makePendingKey() -> String {
        "pending-\(UUID().uuidString)"
    }

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("PalmPhotos", isDirectory: true)
    }

    static func url(for key: String) -> URL? {
        let candidate = directory.appendingPathComponent(safe(key)).appendingPathExtension("jpg")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    @discardableResult
    static func save(_ image: UIImage, key: String = pendingKey) -> URL? {
        guard let data = ImagePreprocessor.jpegDataForLocalStorage(from: image) else { return nil }
        return save(data, key: key)
    }

    @discardableResult
    static func save(_ data: Data, key: String = pendingKey) -> URL? {
        do {
            try ensureDirectory()
            let destination = directory.appendingPathComponent(safe(key)).appendingPathExtension("jpg")
            try data.write(to: destination, options: [.atomic])
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutable = destination
            try? mutable.setResourceValues(values)
            return destination
        } catch {
            return nil
        }
    }

    @discardableResult
    static func bind(pendingKey: String = Self.pendingKey, to readingId: String) -> URL? {
        guard let pending = url(for: pendingKey) else { return nil }
        let destination = directory.appendingPathComponent(safe(readingId)).appendingPathExtension("jpg")
        do {
            if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
            try FileManager.default.moveItem(at: pending, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    static func prune(keepMostRecent: Int) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: []) else { return }
        let jpgs = files.filter { $0.pathExtension.lowercased() == "jpg" }
        let sorted = jpgs.sorted { lhs, rhs in
            (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast >
            (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
        }
        for file in sorted.dropFirst(max(0, keepMostRecent)) { try? FileManager.default.removeItem(at: file) }
    }

    static var count: Int {
        ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .count
    }

    static func clearAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files { try? FileManager.default.removeItem(at: file) }
    }

    private static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = directory
        try? mutable.setResourceValues(values)
    }

    private static func safe(_ key: String) -> String {
        key.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
    }
}
