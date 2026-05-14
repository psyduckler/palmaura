import Foundation

enum ReadingStatus: String, Codable { case ok, notPalm = "not_palm", badImage = "bad_image" }
enum AuraColor: String, Codable { case violet, gold, fire, moon, water, rose }
enum ShareCardFormat: String, Codable { case aura, archetype, thirtyDay = "thirty_day", palmMap = "palm_map" }
enum ShareCardTheme: String, Codable { case moon, fire, water, gold, violet, rose }

struct PalmReadingResponse: Codable, Equatable, Identifiable {
    var id: String { readingId }
    let status: ReadingStatus
    let readingId: String
    let title: String
    let oneLineSummary: String
    let auraColor: AuraColor
    let archetype: String
    let shareCards: [ShareCard]
    let palmLines: PalmLineSet?
    let report: ReadingReport
    let rejectionMessage: String?
    let nextReadingHook: NextReadingHook?
    let entertainmentDisclaimer: String
    let createdAt: String

    func replacingPalmLines(_ palmLines: PalmLineSet?) -> PalmReadingResponse {
        PalmReadingResponse(status: status, readingId: readingId, title: title, oneLineSummary: oneLineSummary, auraColor: auraColor, archetype: archetype, shareCards: shareCards, palmLines: palmLines, report: report, rejectionMessage: rejectionMessage, nextReadingHook: nextReadingHook, entertainmentDisclaimer: entertainmentDisclaimer, createdAt: createdAt)
    }
}

struct ShareCard: Codable, Equatable, Identifiable {
    var id: String { format.rawValue }
    let format: ShareCardFormat
    let title: String
    let body: String
    let accentColor: String
    let theme: ShareCardTheme
}

struct ReadingReport: Codable, Equatable {
    let aura: String
    let heartLine: String
    let headLine: String
    let lifeLine: String
    let fateLine: String
    let currentSeason: String
    let guidance: String
    let ritual: String
}

struct NextReadingHook: Codable, Equatable {
    let focus: ReadingFocus
    let teaser: String
}
