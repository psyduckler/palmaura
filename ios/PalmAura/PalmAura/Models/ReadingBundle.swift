import Foundation

struct ReadingBundle: Equatable {
    let reading: PalmReadingResponse
    let photoURL: URL?
    let lineSet: PalmLineSet
    let auraColor: AuraColor

    init(reading: PalmReadingResponse, photoURL: URL?, lineSet: PalmLineSet? = nil) {
        self.reading = reading
        self.photoURL = photoURL
        self.lineSet = lineSet ?? reading.palmLines ?? PalmLineSet.fallback
        self.auraColor = reading.auraColor
    }

    static func restore(reading: PalmReadingResponse) -> ReadingBundle {
        ReadingBundle(
            reading: reading,
            photoURL: PalmPhotoStore.url(for: reading.readingId),
            lineSet: PalmLineSetStore.load(for: reading.readingId) ?? reading.palmLines
        )
    }

    var hasPhoto: Bool {
        guard let photoURL else { return false }
        return FileManager.default.fileExists(atPath: photoURL.path)
    }

    var shouldUsePreciseLines: Bool { lineSet.source == .aiDetected && lineSet.confidence >= 0.55 }

    var augmentedShareCards: [ShareCard] {
        guard hasPhoto else { return reading.shareCards }
        if reading.shareCards.contains(where: { $0.format == .palmMap }) { return reading.shareCards }
        let card = ShareCard(format: .palmMap, title: "Palm Map", body: reading.oneLineSummary, accentColor: "#F6D27A", theme: .gold)
        return reading.shareCards + [card]
    }
}
