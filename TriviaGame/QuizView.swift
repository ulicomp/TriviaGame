import SwiftUI

struct QuizView: View {
    let questions: [PreparedTriviaQuestion]
    @Binding var currentQuestionIndex: Int
    @Binding var selectedAnswerIDs: [PreparedTriviaQuestion.ID: TriviaAnswerChoice.ID]
    let remainingSeconds: Int
    let unansweredCount: Int
    let onSubmit: () -> Void
    let onChangeOptions: () -> Void

    @State private var isShowingUnansweredConfirmation = false

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
                            gameHeader
                            progressHeader

                            ScrollView {
                                QuestionCard(
                                    question: currentQuestion,
                                    selectedAnswerID: selectedAnswerIDs[currentQuestion.id],
                                    onSelectAnswer: { answerID in
                                        selectedAnswerIDs[currentQuestion.id] = answerID
                                    }
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
            .confirmationDialog(
                unansweredConfirmationTitle,
                isPresented: $isShowingUnansweredConfirmation,
                titleVisibility: .visible
            ) {
                Button("Submit Anyway", action: onSubmit)
                Button("Keep Reviewing", role: .cancel) {}
            } message: {
                Text("Unanswered questions count as incorrect.")
            }
        }
    }

    private var gameHeader: some View {
        HStack(spacing: 8) {
            Button(action: onChangeOptions) {
                Label("Options", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(minHeight: 44)
            .layoutPriority(2)
            .accessibilityLabel("Change Options")
            .accessibilityHint("Ends this quiz and returns to quiz options")

            Spacer(minLength: 2)

            Text("Trivia Quiz")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 2)

            QuizTimerPill(remainingSeconds: remainingSeconds)
                .layoutPriority(3)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Question \(currentQuestionIndex + 1)")
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
        .accessibilityLabel("Quiz progress")
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

            if currentQuestionIndex < questions.index(before: questions.endIndex) {
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
            } else {
                Button(action: requestSubmission) {
                    HStack {
                        Text("Submit Quiz")
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .buttonStyle(TriviaGamePrimaryButtonStyle())
                .accessibilityHint("Finishes the quiz and calculates your score")
            }
        }
    }

    private var unansweredConfirmationTitle: String {
        let noun = unansweredCount == 1 ? "question" : "questions"
        return "You have \(unansweredCount) unanswered \(noun). Submit anyway?"
    }

    private func requestSubmission() {
        if unansweredCount > 0 {
            isShowingUnansweredConfirmation = true
        } else {
            onSubmit()
        }
    }

    private var unavailableContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 44))
                .foregroundStyle(TriviaTheme.primary)
                .accessibilityHidden(true)

            Text("Quiz Unavailable")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("The current question could not be displayed.")
                .foregroundStyle(.white.opacity(0.76))
            Button("Return to Options", action: onChangeOptions)
                .buttonStyle(TriviaGamePrimaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .padding(TriviaTheme.horizontalPadding)
    }
}

private struct QuizTimerPill: View {
    let remainingSeconds: Int

    private var color: Color {
        if remainingSeconds <= 10 {
            return TriviaTheme.error
        }
        if remainingSeconds <= 30 {
            return TriviaTheme.warning
        }
        return TriviaTheme.primary
    }

    private var backgroundColor: Color {
        if remainingSeconds <= 10 {
            return Color(red: 1.0, green: 0.91, blue: 0.92)
        }
        if remainingSeconds <= 30 {
            return Color(red: 1.0, green: 0.94, blue: 0.84)
        }
        return .white
    }

    var body: some View {
        Label(QuizTimer.formattedTime(remainingSeconds), systemImage: "clock.fill")
            .font(.subheadline.monospacedDigit().weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(backgroundColor, in: Capsule())
            .overlay {
                Capsule().stroke(color.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: color.opacity(0.12), radius: 6, y: 3)
            .fixedSize(horizontal: true, vertical: false)
            .animation(.easeInOut(duration: 0.2), value: color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time remaining")
            .accessibilityValue(QuizTimer.accessibilityDescription(remainingSeconds))
    }
}

private struct QuestionCard: View {
    let question: PreparedTriviaQuestion
    let selectedAnswerID: TriviaAnswerChoice.ID?
    let onSelectAnswer: (TriviaAnswerChoice.ID) -> Void

    var body: some View {
        TriviaCard {
            VStack(alignment: .leading, spacing: 22) {
                categoryAndDifficulty

                Text(question.questionText)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 12) {
                    ForEach(question.answerChoices) { answer in
                        AnswerOptionView(
                            answer: answer,
                            isSelected: selectedAnswerID == answer.id,
                            onSelect: { onSelectAnswer(answer.id) }
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
}

private struct AnswerOptionView: View {
    let answer: TriviaAnswerChoice
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(isSelected ? TriviaTheme.primary : TriviaTheme.surfaceTint)
                        .frame(width: 30, height: 30)

                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? .white : TriviaTheme.primary.opacity(0.55))
                }
                .accessibilityHidden(true)

                Text(answer.text)
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .foregroundStyle(isSelected ? TriviaTheme.primaryDeep : TriviaTheme.textPrimary)
            .background(
                isSelected ? TriviaTheme.primary.opacity(0.10) : TriviaTheme.background.opacity(0.55),
                in: RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
                    .stroke(
                        isSelected ? TriviaTheme.primary : TriviaTheme.border.opacity(0.8),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(color: isSelected ? TriviaTheme.primary.opacity(0.10) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(answer.text)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
