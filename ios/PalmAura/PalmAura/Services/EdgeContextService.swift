import Foundation

struct EdgeLocationContext: Codable, Equatable {
    var city: String?
    var region: String?
    var country: String?
    var timezone: String?

    var displayName: String? {
        let parts = [city, region, country]
            .compactMap { value -> String? in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }
}

enum EdgeContextService {
    static func fetchIfFast(timeoutNanoseconds: UInt64 = 1_500_000_000) async -> EdgeLocationContext? {
        await withTaskGroup(of: EdgeLocationContext?.self) { group in
            group.addTask { await fetch() }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }

            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private static func fetch() async -> EdgeLocationContext? {
        let url = AppConfig.readingAPIBaseURL.appending(path: "/api/edge-context")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            return try JSONDecoder().decode(EdgeLocationContext.self, from: data)
        } catch {
            return nil
        }
    }
}
