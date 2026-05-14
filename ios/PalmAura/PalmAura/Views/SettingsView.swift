import SwiftUI

struct SettingsView: View {
    @State private var lastReading = LastReadingStore.load()
    @State private var savedPalmPhotoCount = PalmPhotoStore.count
    @State private var savedPersonalization = PersonalizationStore.load()

    var body: some View {
        List {
            if let lastReading {
                let bundle = ReadingBundle.restore(reading: lastReading)
                NavigationLink("Your last reading") { ReadingResultView(bundle: bundle) }
                if bundle.hasPhoto {
                    NavigationLink("Open palm map") { PalmMapView(bundle: bundle) }
                }
            }

            Section("Privacy") {
                Text("PalmAura sends your palm image only for the reading request. Saved palm photos stay on this device for reveal, palm-map browsing, and sharing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Your one-time profile — birthday, gender, and dominant hand — is stored on this device and sent with reading requests for context. Free-form questions are not collected or saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Saved palm photos: \(savedPalmPhotoCount)")
                if let savedPersonalization {
                    Text(personalizationSummary(savedPersonalization))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No saved personalization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Clear saved personalization", role: .destructive) {
                    PersonalizationStore.clear()
                    savedPersonalization = nil
                }
                .disabled(savedPersonalization == nil)
                Button("Delete saved palm photos", role: .destructive) {
                    PalmPhotoStore.clearAll()
                    savedPalmPhotoCount = PalmPhotoStore.count
                }
                .disabled(savedPalmPhotoCount == 0)
            }

            Section("Links") {
                Link("Privacy Policy", destination: URL(string: "\(BrandConfig.websiteURL)/privacy.html")!)
                Link("Terms", destination: URL(string: "\(BrandConfig.websiteURL)/terms.html")!)
            }

            Button("Clear last reading") {
                LastReadingStore.clear()
                lastReading = nil
                savedPalmPhotoCount = PalmPhotoStore.count
            }

            Section("About") {
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")")
                Text(BrandConfig.entertainmentDisclaimer).font(.caption)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            lastReading = LastReadingStore.load()
            savedPalmPhotoCount = PalmPhotoStore.count
            savedPersonalization = PersonalizationStore.load()
        }
    }

    private func personalizationSummary(_ personalization: ReadingPersonalization) -> String {
        var parts: [String] = []
        if let gender = personalization.gender { parts.append("gender: \(gender.displayName.lowercased())") }
        if let handedness = personalization.handedness { parts.append("dominant hand: \(handedness.displayName.lowercased())") }
        if let birthDate = personalization.birthDate {
            let month = Calendar.current.monthSymbols[birthDate.month - 1]
            parts.append("birthday: \(month) \(birthDate.day), \(birthDate.year)")
        }
        return parts.isEmpty ? "No saved personalization" : parts.joined(separator: " · ")
    }
}
