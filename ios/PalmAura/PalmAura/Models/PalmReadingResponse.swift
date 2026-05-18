import Foundation

enum ReadingStatus: String, Codable { case ok, notPalm = "not_palm", badImage = "bad_image" }
enum AuraColor: String, Codable { case violet, gold, fire, moon, water, rose }
enum InferredScannedHand: String, Codable { case left, right, unknown }
enum InferredHandRole: String, Codable { case dominant, nonDominant = "non_dominant", ambidextrous, unknown }

struct InferredScannedHandContext: Codable, Equatable {
    let hand: InferredScannedHand
    let confidence: Double
    let role: InferredHandRole
    let evidence: String
}

struct PalmReadingResponse: Codable, Equatable, Identifiable {
    var id: String { readingId }
    let status: ReadingStatus
    let readingId: String
    let title: String
    let oneLineSummary: String
    let auraColor: AuraColor
    let archetype: String
    let palmLines: PalmLineSet?
    let inferredScannedHand: InferredScannedHandContext?
    let report: ReadingReport
    let rejectionMessage: String?
    let nextReadingHook: NextReadingHook?
    let entertainmentDisclaimer: String
    let createdAt: String

    func replacingPalmLines(_ palmLines: PalmLineSet?) -> PalmReadingResponse {
        PalmReadingResponse(status: status, readingId: readingId, title: title, oneLineSummary: oneLineSummary, auraColor: auraColor, archetype: archetype, palmLines: palmLines, inferredScannedHand: inferredScannedHand, report: report, rejectionMessage: rejectionMessage, nextReadingHook: nextReadingHook, entertainmentDisclaimer: entertainmentDisclaimer, createdAt: createdAt)
    }
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
