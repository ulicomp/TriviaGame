import SwiftUI

struct QuizReviewView: View {
    let questions: [PreparedTriviaQuestion]
    let selectedAnswerIDs: [PreparedTriviaQuestion.ID: TriviaAnswerChoice.ID]
    let onBackToResults: () -> Void

    @State private var currentQuestionIndex = 0

    private var currentQuestion: PreparedTriviaQuestion? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if let currentQuestion {
                    VStack(spacing: 16) {
                        Text("Review \(currentQuestionIndex + 1) of \(questions.count)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Answer review progress")
                            .accessibilityValue("Question \(currentQuestionIndex + 1) of \(questions.count)")

                        ScrollView {
                            ReviewQuestionCard(
                                question: currentQuestion,
                                selectedAnswerID: selectedAnswerIDs[currentQuestion.id]
                            )
                            .padding(.vertical, 4)
                        }

                        navigationControls
                    }
                    .padding()
                } else {
                    unavailableContent
                }
            }
            .navigationTitle("Review Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back to Results", action: onBackToResults)
                }
            }
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            Button("Previous") {
                guard currentQuestionIndex > questions.startIndex else { return }
                currentQuestionIndex -= 1
            }
            .buttonStyle(.bordered)
            .disabled(currentQuestionIndex == questions.startIndex)

            Spacer()

            Button("Next") {
                let nextIndex = currentQuestionIndex + 1
                guard questions.indices.contains(nextIndex) else { return }
                currentQuestionIndex = nextIndex
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(currentQuestionIndex + 1 >= questions.count)
        }
    }

    private var unavailableContent: some View {
        VStack(spacing: 16) {
            Text("Review Unavailable")
                .font(.title2.bold())
            Text("This answer review could not be displayed.")
                .foregroundStyle(.secondary)
            Button("Back to Results", action: onBackToResults)
                .buttonStyle(.borderedProminent)
                .tint(.purple)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

private struct ReviewQuestionCard: View {
    let question: PreparedTriviaQuestion
    let selectedAnswerID: TriviaAnswerChoice.ID?

    private var selectedAnswer: TriviaAnswerChoice? {
        guard let selectedAnswerID else { return nil }
        return question.answerChoices.first(where: { $0.id == selectedAnswerID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(question.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.purple)

                Text(question.difficulty.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(question.questionText)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            outcomeLabel

            VStack(spacing: 12) {
                ForEach(question.answerChoices) { answer in
                    ReviewAnswerOption(
                        answer: answer,
                        state: reviewState(for: answer)
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        )
    }

    @ViewBuilder
    private var outcomeLabel: some View {
        if let selectedAnswer {
            Label(
                selectedAnswer.isCorrect ? "Answered correctly" : "Answered incorrectly",
                systemImage: selectedAnswer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selectedAnswer.isCorrect ? Color.green : Color.red)
        } else {
            Label("Not answered", systemImage: "minus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .accessibilityLabel("Not answered")
        }
    }

    private func reviewState(for answer: TriviaAnswerChoice) -> ReviewAnswerState {
        if answer.id == selectedAnswer?.id {
            return answer.isCorrect ? .selectedCorrect : .selectedIncorrect
        }
        if answer.isCorrect {
            return .correctAnswer
        }
        return .neutral
    }
}

private struct ReviewAnswerOption: View {
    let answer: TriviaAnswerChoice
    let state: ReviewAnswerState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(answer.text)
                    .fixedSize(horizontal: false, vertical: true)

                if let statusText = state.statusText {
                    Text(statusText)
                        .font(.caption.weight(.semibold))
                }
            }

            Spacer(minLength: 8)

            if let symbolName = state.symbolName {
                Image(systemName: symbolName)
                    .accessibilityHidden(true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(state.foregroundColor)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(state.backgroundColor)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(state.borderColor, lineWidth: state == .neutral ? 1 : 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(answer.text)
        .accessibilityValue(state.accessibilityValue)
    }
}

private enum ReviewAnswerState: Equatable {
    case neutral
    case selectedCorrect
    case selectedIncorrect
    case correctAnswer

    var foregroundColor: Color {
        switch self {
        case .neutral: .primary
        case .selectedCorrect, .correctAnswer: .green
        case .selectedIncorrect: .red
        }
    }

    var backgroundColor: Color {
        switch self {
        case .neutral: Color.secondary.opacity(0.08)
        case .selectedCorrect, .correctAnswer: Color.green.opacity(0.12)
        case .selectedIncorrect: Color.red.opacity(0.12)
        }
    }

    var borderColor: Color {
        switch self {
        case .neutral: Color.secondary.opacity(0.3)
        case .selectedCorrect, .correctAnswer: .green
        case .selectedIncorrect: .red
        }
    }

    var symbolName: String? {
        switch self {
        case .neutral: nil
        case .selectedCorrect, .correctAnswer: "checkmark.circle.fill"
        case .selectedIncorrect: "xmark.circle.fill"
        }
    }

    var statusText: String? {
        switch self {
        case .neutral: nil
        case .selectedCorrect: "Your answer · Correct"
        case .selectedIncorrect: "Your answer · Incorrect"
        case .correctAnswer: "Correct answer"
        }
    }

    var accessibilityValue: String {
        switch self {
        case .neutral: "Answer option"
        case .selectedCorrect: "Selected answer, correct"
        case .selectedIncorrect: "Selected answer, incorrect"
        case .correctAnswer: "Correct answer"
        }
    }
}
