import Foundation

struct TriviaService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchQuestions(configuration: TriviaConfiguration) async throws -> [TriviaQuestion] {
        let url = try makeURL(for: configuration)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TriviaServiceError.invalidServerResponse
        }

        let triviaResponse: TriviaResponse
        do {
            triviaResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)
        } catch {
            throw TriviaServiceError.decodingFailed
        }

        guard triviaResponse.responseCode == 0 else {
            throw TriviaServiceError.apiResponseCode(triviaResponse.responseCode)
        }

        return triviaResponse.results
    }

    private func makeURL(for configuration: TriviaConfiguration) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "opentdb.com"
        components.path = "/api.php"

        var queryItems = [
            URLQueryItem(name: "amount", value: String(configuration.questionCount)),
            URLQueryItem(name: "type", value: configuration.questionType.apiValue)
        ]

        if let category = configuration.category.apiValue {
            queryItems.append(URLQueryItem(name: "category", value: String(category)))
        }

        if let difficulty = configuration.difficulty.apiValue {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw TriviaServiceError.invalidURL
        }

        return url
    }
}

enum TriviaServiceError: LocalizedError {
    case invalidURL
    case invalidServerResponse
    case decodingFailed
    case apiResponseCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The trivia request could not be created. Please try again."
        case .invalidServerResponse:
            "The trivia server returned an unexpected response. Please try again."
        case .decodingFailed:
            "The trivia data could not be read. Please try again."
        case .apiResponseCode(let code):
            switch code {
            case 1:
                "No questions matched these options. Try a different category or difficulty."
            case 2:
                "The trivia service rejected an invalid request parameter."
            case 3:
                "The trivia session token was not found."
            case 4:
                "The trivia session token has no remaining questions."
            case 5:
                "Too many trivia requests were sent. Please wait a moment and try again."
            default:
                "The trivia service returned an unknown error (code \(code))."
            }
        }
    }
}
