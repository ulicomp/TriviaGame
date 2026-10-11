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

    private var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }

    var body: some View {
        NavigationStack {
            TriviaGameBackground {
                Group {
                    if let currentQuestion {
                        VStack(spacing: 16) {
                            reviewHeader
                            reviewProgress

                            ScrollView {
                                ReviewQuestionCard(
                                    question: currentQuestion,
                                    selectedAnswerID: selectedAnswerIDs[currentQuestion.id]
                                )
                                .id(currentQuestion.id)
                                .transition(.opacity.combined(with: .scale(scale: 0.99)))
                                .padding(.vertical, 4)
                            }
                            .scrollIndicators(.hidden)

                            navigationControls
                        }
                        .padding(.horizontal, TriviaTheme.horizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .animation(.easeInOut(duration: 0.22), value: currentQuestionIndex)
                    } else {
                        unavailableContent
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var reviewHeader: some View {
        HStack(spacing: 10) {
            Button(action: onBackToResults) {
                Label("Results", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(minHeight: 44)
            .accessibilityLabel("Back to Results")

            Spacer()

            Text("Answer Review")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private var reviewProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Review \(currentQuestionIndex + 1)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("of \(questions.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }

            TriviaProgressBar(progress: progress, onDarkBackground: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Answer review progress")
        .accessibilityValue("Question \(currentQuestionIndex + 1) of \(questions.count)")
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            Button {
                guard currentQuestionIndex > questions.startIndex else { return }
                currentQuestionIndex -= 1
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .buttonStyle(TriviaGameSecondaryButtonStyle())
            .disabled(currentQuestionIndex == questions.startIndex)
            .opacity(currentQuestionIndex == questions.startIndex ? 0.45 : 1)

            Button {
                let nextIndex = currentQuestionIndex + 1
                guard questions.indices.contains(nextIndex) else { return }
                currentQuestionIndex = nextIndex
            } label: {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(TriviaGamePrimaryButtonStyle())
            .disabled(currentQuestionIndex + 1 >= questions.count)
            .opacity(currentQuestionIndex + 1 >= questions.count ? 0.45 : 1)
        }
    }

    private var unavailableContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.questionmark.fill")
                .font(.system(size: 44))
                .foregroundStyle(TriviaTheme.primary)
                .accessibilityHidden(true)
            Text("Review Unavailable")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("This answer review could not be displayed.")
                .foregroundStyle(.white.opacity(0.76))
            Button("Back to Results", action: onBackToResults)
                .buttonStyle(TriviaGamePrimaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .padding(TriviaTheme.horizontalPadding)
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
        TriviaCard {
            VStack(alignment: .leading, spacing: 20) {
                categoryAndDifficulty

                Text(question.questionText)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

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
        }
    }

    private var categoryAndDifficulty: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                TriviaCapsuleLabel(title: question.category, systemImage: "sparkles")
                TriviaCapsuleLabel(
                    title: question.difficulty.capitalized,
                    systemImage: "chart.bar.fill",
                    color: TriviaTheme.accent
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                TriviaCapsuleLabel(title: question.category, systemImage: "sparkles")
                TriviaCapsuleLabel(
                    title: question.difficulty.capitalized,
                    systemImage: "chart.bar.fill",
                    color: TriviaTheme.accent
                )
            }
        }
    }

    @ViewBuilder
    private var outcomeLabel: some View {
        if let selectedAnswer {
            let isCorrect = selectedAnswer.isCorrect
            Label(
                isCorrect ? "Answered correctly" : "Answered incorrectly",
                systemImage: isCorrect ? "checkmark.seal.fill" : "xmark.circle.fill"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isCorrect ? TriviaTheme.success : TriviaTheme.error)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                (isCorrect ? TriviaTheme.success : TriviaTheme.error).opacity(0.10),
                in: Capsule()
            )
        } else {
            Label("Not answered", systemImage: "minus.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TriviaTheme.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(TriviaTheme.warning.opacity(0.10), in: Capsule())
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
        HStack(spacing: 13) {
            Image(systemName: state.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(state.foregroundColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(answer.text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(TriviaTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let statusText = state.statusText {
                    Text(statusText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(state.foregroundColor)
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(state.backgroundColor, in: RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
                .stroke(state.borderColor, lineWidth: state == .neutral ? 1 : 1.5)
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
        case .neutral: TriviaTheme.textSecondary
        case .selectedCorrect, .correctAnswer: TriviaTheme.success
        case .selectedIncorrect: TriviaTheme.error
        }
    }

    var backgroundColor: Color {
        switch self {
        case .neutral: TriviaTheme.background.opacity(0.55)
        case .selectedCorrect, .correctAnswer: TriviaTheme.success.opacity(0.10)
        case .selectedIncorrect: TriviaTheme.error.opacity(0.10)
        }
    }

    var borderColor: Color {
        switch self {
        case .neutral: TriviaTheme.border.opacity(0.8)
        case .selectedCorrect, .correctAnswer: TriviaTheme.success.opacity(0.65)
        case .selectedIncorrect: TriviaTheme.error.opacity(0.65)
        }
    }

    var symbolName: String {
        switch self {
        case .neutral: "circle"
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
