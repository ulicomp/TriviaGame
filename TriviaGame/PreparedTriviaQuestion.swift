import Foundation

struct PreparedTriviaQuestion: Identifiable {
    let id: Int
    let questionText: String
    let category: String
    let difficulty: String
    let type: String
    let correctAnswer: String
    let answerChoices: [TriviaAnswerChoice]

    static func prepare(_ questions: [TriviaQuestion]) throws -> [PreparedTriviaQuestion] {
        guard !questions.isEmpty else {
            throw QuizPreparationError.noQuestions
        }

        return try questions.enumerated().map { index, question in
            try PreparedTriviaQuestion(id: index, question: question)
        }
    }

    private init(id: Int, question: TriviaQuestion) throws {
        let decodedQuestion = HTMLTextDecoder.decode(question.question)
        let decodedCorrectAnswer = HTMLTextDecoder.decode(question.correctAnswer)
        let decodedIncorrectAnswers = question.incorrectAnswers.map(HTMLTextDecoder.decode)

        guard !decodedQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !decodedCorrectAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw QuizPreparationError.invalidQuestion(number: id + 1)
        }

        let answerTexts: [String]
        if question.type == "boolean" {
            answerTexts = ["True", "False"]
        } else {
            let combinedAnswers = [decodedCorrectAnswer] + decodedIncorrectAnswers
            guard combinedAnswers.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                throw QuizPreparationError.invalidQuestion(number: id + 1)
            }
            answerTexts = combinedAnswers.shuffled()
        }

        self.id = id
        questionText = decodedQuestion
        category = HTMLTextDecoder.decode(question.category)
        difficulty = HTMLTextDecoder.decode(question.difficulty)
        type = HTMLTextDecoder.decode(question.type)
        correctAnswer = decodedCorrectAnswer
        answerChoices = answerTexts.enumerated().map { choiceIndex, answer in
            TriviaAnswerChoice(id: choiceIndex, text: answer)
        }
    }
}

struct TriviaAnswerChoice: Identifiable {
    let id: Int
    let text: String
}

enum QuizPreparationError: LocalizedError {
    case noQuestions
    case invalidQuestion(number: Int)

    var errorDescription: String? {
        switch self {
        case .noQuestions:
            "The trivia service returned no questions. Please try different options."
        case .invalidQuestion(let number):
            "Question \(number) could not be prepared. Please try loading a new quiz."
        }
    }
}
