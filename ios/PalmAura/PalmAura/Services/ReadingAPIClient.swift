import Foundation

enum ReadingError: Error, LocalizedError {
    case rateLimited(String)
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .rateLimited(let message): return message
        case .invalidResponse: return "The reading came back in an unexpected form."
        case .server(let message): return message
        }
    }
}

final class ReadingAPIClient {
    func createReading(_ request: PalmReadingRequest) async throws -> PalmReadingResponse {
        var urlRequest = URLRequest(url: AppConfig.readingAPIBaseURL.appending(path: "/api/read"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw ReadingError.invalidResponse }
        if http.statusCode == 429 {
            let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).message) ?? "You've used your free readings today. Come back tomorrow ✨"
            throw ReadingError.rateLimited(message)
        }
        guard 200..<300 ~= http.statusCode else {
            let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).message) ?? "The reading was interrupted. Try again."
            throw ReadingError.server(message)
        }
        return try JSONDecoder().decode(PalmReadingResponse.self, from: data)
    }
}

private struct APIErrorResponse: Decodable { let message: String }
