import Foundation

struct ReadingReflection: Codable, Identifiable, Equatable {
    let id: UUID
    let readingId: String
    let promptKey: String
    var response: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        readingId: String,
        promptKey: String,
        response: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.readingId = readingId
        self.promptKey = promptKey
        self.response = response
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Stable prompts shown after every reading. The raw values are persisted,
/// so the questions can evolve without breaking saved journal entries.
enum ReflectionPrompt: String, CaseIterable, Identifiable {
    case feelsTrueToday = "feels_true_today"
    case readyToLetGo = "ready_to_let_go"
    case smallAction = "small_action"

    var id: String { rawValue }

    var question: String {
        switch self {
        case .feelsTrueToday:
            return "What part of this feels true today?"
        case .readyToLetGo:
            return "What are you ready to let go of?"
        case .smallAction:
            return "What is one small action for this week?"
        }
    }

    var placeholder: String {
        switch self {
        case .feelsTrueToday:
            return "The line about patience felt sharp…"
        case .readyToLetGo:
            return "I'm done waiting on…"
        case .smallAction:
            return "This week I will…"
        }
    }
}
