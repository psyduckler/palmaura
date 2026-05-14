import Foundation

enum PalmLine: String, CaseIterable, Codable, Identifiable {
    case heart
    case head
    case life
    case fate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .heart: return "Heart Line"
        case .head: return "Head Line"
        case .life: return "Life Line"
        case .fate: return "Fate Line"
        }
    }

    var domain: String {
        switch self {
        case .heart: return "Love + emotional weather"
        case .head: return "Mind + choices"
        case .life: return "Vitality + rhythm"
        case .fate: return "Purpose + direction"
        }
    }

    var symbolName: String {
        switch self {
        case .heart: return "heart.fill"
        case .head: return "brain.head.profile"
        case .life: return "leaf.fill"
        case .fate: return "sparkles"
        }
    }
}

extension PalmReadingResponse {
    func reportText(for line: PalmLine) -> String {
        switch line {
        case .heart: return report.heartLine
        case .head: return report.headLine
        case .life: return report.lifeLine
        case .fate: return report.fateLine
        }
    }
}
