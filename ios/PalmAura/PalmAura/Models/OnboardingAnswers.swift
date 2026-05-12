import Foundation

enum ReadingFocus: String, Codable, CaseIterable, Identifiable {
    case love, career, selfGrowth = "self", purpose, general
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .love: return "Love"
        case .career: return "Career"
        case .selfGrowth: return "Self"
        case .purpose: return "Purpose"
        case .general: return "General"
        }
    }
}

enum LifeSeason: String, Codable, CaseIterable, Identifiable {
    case newBeginning = "new_beginning"
    case bigDecision = "big_decision"
    case healing
    case buildingMomentum = "building_momentum"
    case feelingStuck = "feeling_stuck"
    case unknown
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .newBeginning: return "New beginning"
        case .bigDecision: return "Big decision"
        case .healing: return "Healing"
        case .buildingMomentum: return "Building momentum"
        case .feelingStuck: return "Feeling stuck"
        case .unknown: return "Skip"
        }
    }
}

enum ReadingStyle: String, Codable, CaseIterable, Identifiable {
    case gentle, direct, mysterious
    case deepSpiritual = "deep_spiritual"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .direct: return "Direct"
        case .mysterious: return "Mysterious"
        case .deepSpiritual: return "Deep spiritual"
        }
    }
}

struct OnboardingAnswers: Codable, Equatable {
    var focus: ReadingFocus
    var lifeSeason: LifeSeason
    var readingStyle: ReadingStyle

    static let `default` = OnboardingAnswers(focus: .general, lifeSeason: .unknown, readingStyle: .mysterious)
}
