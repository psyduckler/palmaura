import Foundation
import UIKit

/// Builds the system-share payload for a completed palm reading.
///
/// Important: do not pass `BrandConfig.websiteURL` as a standalone `URL` item.
/// Many `UIActivityViewController` destinations prioritize URL metadata and
/// will share only the website preview, dropping the reading/card. Keeping the
/// site inside the reading text preserves attribution without turning the share
/// action into a generic palmaura.app link share.
enum ShareReportPayload {
    static func activityItems(image: UIImage, reading: PalmReadingResponse) -> [Any] {
        [image, text(for: reading)]
    }

    static func text(for reading: PalmReadingResponse) -> String {
        let reportSections = [
            ("Heart line", reading.report.heartLine),
            ("Head line", reading.report.headLine),
            ("Life line", reading.report.lifeLine),
            ("Fate line", reading.report.fateLine),
            ("Current season", reading.report.currentSeason),
            ("Guidance", reading.report.guidance),
            ("Ritual", reading.report.ritual)
        ]
        .compactMap { title, body -> String? in
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return "\(title): \(trimmed)"
        }
        .joined(separator: "\n\n")

        let attribution = "Create yours: \(BrandConfig.websiteURL)"
        let disclaimer = reading.entertainmentDisclaimer.trimmingCharacters(in: .whitespacesAndNewlines)
        let footer = disclaimer.isEmpty ? attribution : "\(disclaimer)\n\n\(attribution)"

        return [
            "My \(BrandConfig.appName) reading: \(reading.title)",
            reading.oneLineSummary,
            "Archetype: \(reading.archetype)\nAura: \(auraLabel(for: reading.auraColor))",
            reportSections,
            footer
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    private static func auraLabel(for auraColor: AuraColor) -> String {
        switch auraColor {
        case .violet: return "Violet"
        case .gold: return "Golden"
        case .fire: return "Fire"
        case .moon: return "Moon"
        case .water: return "Water"
        case .rose: return "Rose"
        }
    }
}
