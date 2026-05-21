enum BrandConfig {
    static let appName = "PalmAura"
    static let domain = "palmaura.app"
    static let websiteURL = "https://palmaura.app"
    static let socialHandle = "@PalmAuraApp"
    static let supportEmail = "hello@palmaura.app"

    static let shortDisclaimer = "For entertainment only"
    static let entertainmentDisclaimer = "PalmAura readings are symbolic entertainment and self-reflection only. They are not medical, legal, financial, psychological, or life-critical advice."

    /// Convert an integer (e.g. a year) to its Roman-numeral representation.
    /// Used for keepsake-style date stamps in result and settings screens.
    /// Returns an empty string for non-positive input.
    static func romanNumeral(_ n: Int) -> String {
        guard n > 0 else { return "" }
        let pairs: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]
        var num = n
        var result = ""
        for (value, symbol) in pairs {
            while num >= value { result += symbol; num -= value }
        }
        return result
    }
}
