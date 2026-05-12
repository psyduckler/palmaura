import SwiftUI

struct SettingsView: View {
    @State private var lastReading = LastReadingStore.load()
    var body: some View {
        List {
            if let lastReading { NavigationLink("Your last reading") { ReadingResultView(reading: lastReading) } }
            Link("Privacy Policy", destination: URL(string: "\(BrandConfig.websiteURL)/privacy.html")!)
            Link("Terms", destination: URL(string: "\(BrandConfig.websiteURL)/terms.html")!)
            Button("Clear last reading") { LastReadingStore.clear(); lastReading = nil }
            Section("About") { Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")") ; Text(BrandConfig.entertainmentDisclaimer).font(.caption) }
        }.navigationTitle("Settings")
    }
}
