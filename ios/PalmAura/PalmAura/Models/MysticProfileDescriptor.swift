import Foundation

struct MysticProfileDescriptor: Equatable {
    let title: String
    let subtitle: String

    static func make(from personalization: ReadingPersonalization) -> MysticProfileDescriptor {
        guard !personalization.isEmpty else {
            return MysticProfileDescriptor(title: "Starlit Seeker", subtitle: "Profile not set")
        }

        let sign = personalization.birthDate.flatMap(MysticSunSign.init(birthDate:))
        let genderCurrent = personalization.gender?.mysticCurrent
        let handPath = personalization.handedness?.mysticPath
        let seed = deterministicSeed(from: personalization)

        let titleOptions = [
            "\(sign?.displayName ?? "Astral") Oracle",
            "\(sign?.elementName ?? "Velvet") Cartographer",
            "\(genderCurrent?.titleName ?? "Moonlit") Starseer",
            "\(handPath?.titleName ?? "Starlit") Alchemist",
            "\(sign?.rulerName ?? "Hidden Star") Mystic",
            "\(sign?.elementName ?? "Nocturne") Pathfinder",
        ]
        let title = titleOptions[abs(seed) % titleOptions.count]

        var subtitleParts: [String] = []
        if let sign {
            subtitleParts.append("\(sign.displayName) sun")
        }
        if let genderCurrent {
            subtitleParts.append("\(genderCurrent.subtitleName) current")
        }
        if let handPath {
            subtitleParts.append(handPath.subtitleName)
        }

        return MysticProfileDescriptor(
            title: title,
            subtitle: subtitleParts.isEmpty ? "Profile not set" : subtitleParts.joined(separator: " · ")
        )
    }

    private static func deterministicSeed(from personalization: ReadingPersonalization) -> Int {
        var seed = 17
        if let birthDate = personalization.birthDate {
            seed = seed &* 31 &+ birthDate.month
            seed = seed &* 31 &+ birthDate.day
            seed = seed &* 31 &+ birthDate.year
        }
        if let gender = personalization.gender {
            seed = seed &* 31 &+ gender.rawValue.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        }
        if let handedness = personalization.handedness {
            seed = seed &* 31 &+ handedness.rawValue.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        }
        return seed
    }
}

private enum MysticCurrent {
    case lunar, solar, celestial, astral

    var titleName: String {
        switch self {
        case .lunar: return "Lunar"
        case .solar: return "Solar"
        case .celestial: return "Celestial"
        case .astral: return "Astral"
        }
    }

    var subtitleName: String { titleName.lowercased() }
}

private enum MysticHandPath {
    case left, right, twin

    var titleName: String {
        switch self {
        case .left: return "Moon-Hand"
        case .right: return "Sun-Hand"
        case .twin: return "Twin-Hand"
        }
    }

    var subtitleName: String {
        switch self {
        case .left: return "left-hand path"
        case .right: return "right-hand path"
        case .twin: return "dual-hand channel"
        }
    }
}

private extension Gender {
    var mysticCurrent: MysticCurrent {
        switch self {
        case .woman: return .lunar
        case .man: return .solar
        case .nonBinary: return .celestial
        case .preferNotToSay: return .astral
        }
    }
}

private extension Handedness {
    var mysticPath: MysticHandPath {
        switch self {
        case .left: return .left
        case .right: return .right
        case .ambidextrous: return .twin
        }
    }
}

private enum MysticSunSign {
    case aries, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces

    init?(birthDate: BirthDateContext) {
        let md = birthDate.month * 100 + birthDate.day
        switch md {
        case 321...419: self = .aries
        case 420...520: self = .taurus
        case 521...620: self = .gemini
        case 621...722: self = .cancer
        case 723...822: self = .leo
        case 823...922: self = .virgo
        case 923...1022: self = .libra
        case 1023...1121: self = .scorpio
        case 1122...1221: self = .sagittarius
        case 1222...1231, 101...119: self = .capricorn
        case 120...218: self = .aquarius
        case 219...320: self = .pisces
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .aries: return "Aries"
        case .taurus: return "Taurus"
        case .gemini: return "Gemini"
        case .cancer: return "Cancer"
        case .leo: return "Leo"
        case .virgo: return "Virgo"
        case .libra: return "Libra"
        case .scorpio: return "Scorpio"
        case .sagittarius: return "Sagittarius"
        case .capricorn: return "Capricorn"
        case .aquarius: return "Aquarius"
        case .pisces: return "Pisces"
        }
    }

    var elementName: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fire"
        case .taurus, .virgo, .capricorn: return "Earth"
        case .gemini, .libra, .aquarius: return "Air"
        case .cancer, .scorpio, .pisces: return "Water"
        }
    }

    var rulerName: String {
        switch self {
        case .aries: return "Mars"
        case .taurus, .libra: return "Venus"
        case .gemini, .virgo: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .scorpio: return "Pluto"
        case .sagittarius: return "Jupiter"
        case .capricorn: return "Saturn"
        case .aquarius: return "Uranus"
        case .pisces: return "Neptune"
        }
    }
}
