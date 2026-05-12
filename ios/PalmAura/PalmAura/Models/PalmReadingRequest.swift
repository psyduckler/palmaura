import Foundation

struct PalmReadingRequest: Codable, Equatable {
    let clientRequestId: String
    let deviceId: String
    let appVersion: String
    let locale: String
    let imageBase64Jpeg: String
    let onboarding: OnboardingAnswers
}
