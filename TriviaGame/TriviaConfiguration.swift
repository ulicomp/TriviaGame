import Foundation

struct TriviaConfiguration {
    static let questionCountRange = 5...20

    var questionCount = 10
    var category = TriviaCategory.any
    var difficulty = TriviaDifficulty.any
    var questionType = TriviaQuestionType.multipleChoice
}

enum TriviaCategory: String, CaseIterable, Identifiable {
    case any
    case generalKnowledge
    case books
    case film
    case music
    case musicalsAndTheatres
    case television
    case videoGames
    case boardGames
    case scienceAndNature
    case computers
    case mathematics
    case mythology
    case sports
    case geography
    case history
    case politics
    case art
    case celebrities
    case animals
    case vehicles
    case comics
    case gadgets
    case animeAndManga
    case cartoonsAndAnimations

    var id: Self { self }

    var apiValue: Int? {
        switch self {
        case .any: nil
        case .generalKnowledge: 9
        case .books: 10
        case .film: 11
        case .music: 12
        case .musicalsAndTheatres: 13
        case .television: 14
        case .videoGames: 15
        case .boardGames: 16
        case .scienceAndNature: 17
        case .computers: 18
        case .mathematics: 19
        case .mythology: 20
        case .sports: 21
        case .geography: 22
        case .history: 23
        case .politics: 24
        case .art: 25
        case .celebrities: 26
        case .animals: 27
        case .vehicles: 28
        case .comics: 29
        case .gadgets: 30
        case .animeAndManga: 31
        case .cartoonsAndAnimations: 32
        }
    }

    var displayName: String {
        switch self {
        case .any: "Any Category"
        case .generalKnowledge: "General Knowledge"
        case .books: "Entertainment: Books"
        case .film: "Entertainment: Film"
        case .music: "Entertainment: Music"
        case .musicalsAndTheatres: "Entertainment: Musicals & Theatres"
        case .television: "Entertainment: Television"
        case .videoGames: "Entertainment: Video Games"
        case .boardGames: "Entertainment: Board Games"
        case .scienceAndNature: "Science & Nature"
        case .computers: "Science: Computers"
        case .mathematics: "Science: Mathematics"
        case .mythology: "Mythology"
        case .sports: "Sports"
        case .geography: "Geography"
        case .history: "History"
        case .politics: "Politics"
        case .art: "Art"
        case .celebrities: "Celebrities"
        case .animals: "Animals"
        case .vehicles: "Vehicles"
        case .comics: "Entertainment: Comics"
        case .gadgets: "Science: Gadgets"
        case .animeAndManga: "Entertainment: Japanese Anime & Manga"
        case .cartoonsAndAnimations: "Entertainment: Cartoon & Animations"
        }
    }
}

enum TriviaDifficulty: String, CaseIterable, Identifiable {
    case any
    case easy
    case medium
    case hard

    var id: Self { self }

    var apiValue: String? {
        self == .any ? nil : rawValue
    }

    var displayName: String {
        switch self {
        case .any: "Any Difficulty"
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

enum TriviaQuestionType: String, CaseIterable, Identifiable {
    case multipleChoice = "multiple"
    case trueFalse = "boolean"

    var id: Self { self }
    var apiValue: String { rawValue }

    var displayName: String {
        switch self {
        case .multipleChoice: "Multiple Choice"
        case .trueFalse: "True / False"
        }
    }
}
