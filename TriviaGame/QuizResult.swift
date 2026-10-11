import Foundation

struct QuizResult {
    let correctCount: Int
    let totalCount: Int
    let answeredCount: Int
    let completionTimeSeconds: Int

    var unansweredCount: Int {
        max(totalCount - answeredCount, 0)
    }

    var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalCount) * 100).rounded())
    }

    static func calculate(
        questions: [PreparedTriviaQuestion],
        selectedAnswerIDs: [PreparedTriviaQuestion.ID: TriviaAnswerChoice.ID],
        completionTimeSeconds: Int
    ) -> QuizResult {
        var correctCount = 0
        var answeredCount = 0

        for question in questions {
            guard let selectedAnswerID = selectedAnswerIDs[question.id],
                  let selectedAnswer = question.answerChoices.first(where: { $0.id == selectedAnswerID }) else {
                continue
            }

            answeredCount += 1
            if selectedAnswer.isCorrect {
                correctCount += 1
            }
        }

        return QuizResult(
            correctCount: correctCount,
            totalCount: questions.count,
            answeredCount: answeredCount,
            completionTimeSeconds: max(completionTimeSeconds, 0)
        )
    }
}
