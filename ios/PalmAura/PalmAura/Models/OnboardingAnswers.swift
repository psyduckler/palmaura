import Foundation

enum ReadingFocus: String, Codable, CaseIterable, Identifiable {
    case love, career, selfGrowth = "self", purpose, general
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .love: return "Relationship"
        case .career: return "Career"
        case .selfGrowth: return "Self"
        case .purpose: return "The path"
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

struct ReadingSessionIntent: Codable, Equatable {
    var focus: String
    var question: String?

    init(focus: String, question: String?) {
        self.focus = focus
        let trimmed = question?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.question = trimmed.isEmpty ? nil : trimmed
    }

    init?(answers: OnboardingAnswers) {
        let question = answers.personalization?.question?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let focus = answers.sessionIntent?.focus ?? answers.focus.displayName
        guard !question.isEmpty || answers.focus != .general else { return nil }
        self.init(focus: focus, question: question.isEmpty ? nil : question)
    }

    var displaySummary: String {
        if let question, !question.isEmpty { return question }
        return "Focus: \(focus)"
    }
}

struct OnboardingAnswers: Codable, Equatable {
    var focus: ReadingFocus
    var lifeSeason: LifeSeason
    var readingStyle: ReadingStyle
    var personalization: ReadingPersonalization?
    var sessionIntent: ReadingSessionIntent? = nil

    enum CodingKeys: String, CodingKey {
        case focus, lifeSeason, readingStyle, personalization
    }

    static let `default` = OnboardingAnswers(focus: .general, lifeSeason: .unknown, readingStyle: .mysterious, personalization: nil)

    static func forSavedProfile() -> OnboardingAnswers {
        OnboardingAnswers(focus: .general, lifeSeason: .unknown, readingStyle: .mysterious, personalization: PersonalizationStore.load())
    }
}

enum Handedness: String, Codable, CaseIterable, Identifiable {
    case left, right, ambidextrous
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .left: return "Left-handed"
        case .right: return "Right-handed"
        case .ambidextrous: return "Ambidextrous"
        }
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case woman
    case man
    case nonBinary = "non_binary"
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .woman: return "Woman"
        case .man: return "Man"
        case .nonBinary: return "Non-binary"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum ScannedHand: String, Codable, CaseIterable, Identifiable {
    case left, right
    var id: String { rawValue }
    var displayName: String { self == .left ? "Left hand" : "Right hand" }
}

struct BirthDateContext: Codable, Equatable {
    var month: Int
    var day: Int
    var year: Int
}

struct ReadingPersonalization: Codable, Equatable {
    var gender: Gender?
    var handedness: Handedness?
    var scannedHand: ScannedHand?
    var birthDate: BirthDateContext?
    var question: String?
    var timeZoneIdentifier: String?
    var localeRegionCode: String?
    var locationOverride: String?

    enum CodingKeys: String, CodingKey {
        case gender, handedness, scannedHand, birthDate, question
        case timeZoneIdentifier, localeRegionCode, locationOverride
    }

    init(
        gender: Gender? = nil,
        handedness: Handedness? = nil,
        scannedHand: ScannedHand? = nil,
        birthDate: BirthDateContext? = nil,
        question: String? = nil,
        timeZoneIdentifier: String? = nil,
        localeRegionCode: String? = nil,
        locationOverride: String? = nil
    ) {
        self.gender = gender
        self.handedness = handedness
        self.scannedHand = scannedHand
        self.birthDate = birthDate
        self.question = question
        self.timeZoneIdentifier = timeZoneIdentifier
        self.localeRegionCode = localeRegionCode
        self.locationOverride = locationOverride
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        handedness = try container.decodeIfPresent(Handedness.self, forKey: .handedness)
        scannedHand = try container.decodeIfPresent(ScannedHand.self, forKey: .scannedHand)
        birthDate = try? container.decodeIfPresent(BirthDateContext.self, forKey: .birthDate)
        question = try container.decodeIfPresent(String.self, forKey: .question)
        timeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .timeZoneIdentifier)
        localeRegionCode = try container.decodeIfPresent(String.self, forKey: .localeRegionCode)
        locationOverride = try container.decodeIfPresent(String.self, forKey: .locationOverride)
    }

    var withoutQuestion: ReadingPersonalization {
        ReadingPersonalization(
            gender: gender,
            handedness: handedness,
            scannedHand: scannedHand,
            birthDate: birthDate,
            question: nil,
            timeZoneIdentifier: timeZoneIdentifier,
            localeRegionCode: localeRegionCode,
            locationOverride: normalizedLocationOverride
        )
    }

    var normalizedLocationOverride: String? {
        let trimmed = locationOverride?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var isEmpty: Bool {
        gender == nil &&
        handedness == nil &&
        scannedHand == nil &&
        birthDate == nil &&
        (question?.isEmpty ?? true) &&
        (timeZoneIdentifier?.isEmpty ?? true) &&
        (localeRegionCode?.isEmpty ?? true) &&
        normalizedLocationOverride == nil
    }

    var isCompleteProfile: Bool {
        birthDate != nil && gender != nil && handedness != nil
    }
}

enum PersonalizationStore {
    private static let key = "palmaura.personalization.v1"
    static let completionKey = "palmaura.profile.complete.v1"

    static func load() -> ReadingPersonalization? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReadingPersonalization.self, from: data)
    }

    static func hasCompleteProfile() -> Bool {
        load()?.isCompleteProfile == true
    }

    static func save(_ personalization: ReadingPersonalization?) {
        guard let personalization = personalization?.withoutQuestion, !personalization.isEmpty else {
            clear()
            return
        }
        if let data = try? JSONEncoder().encode(personalization) {
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(personalization.isCompleteProfile, forKey: completionKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.set(false, forKey: completionKey)
    }
}
