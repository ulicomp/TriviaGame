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
            Group {
                if let currentQuestion {
                    VStack(spacing: 16) {
                        progressHeader

                        ScrollView {
                            QuestionCard(
                                question: currentQuestion,
                                selectedAnswerID: selectedAnswerIDs[currentQuestion.id],
                                onSelectAnswer: { answerID in
                                    selectedAnswerIDs[currentQuestion.id] = answerID
                                }
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
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Change Options", action: onChangeOptions)
                        .accessibilityHint("Ends this quiz and returns to quiz options")
                }
            }
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

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.headline)

                Spacer()

                QuizTimerBadge(remainingSeconds: remainingSeconds)
            }

            ProgressView(value: progress)
                .tint(.purple)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

            if currentQuestionIndex < questions.index(before: questions.endIndex) {
                Button("Next") {
                    let nextIndex = currentQuestionIndex + 1
                    guard questions.indices.contains(nextIndex) else { return }
                    currentQuestionIndex = nextIndex
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            } else {
                Button("Submit Quiz", action: requestSubmission)
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
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
        VStack(spacing: 16) {
            Text("Quiz Unavailable")
                .font(.title2.bold())
            Text("The current question could not be displayed.")
                .foregroundStyle(.secondary)
            Button("Return to Options", action: onChangeOptions)
                .buttonStyle(.borderedProminent)
                .tint(.purple)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

private struct QuizTimerBadge: View {
    let remainingSeconds: Int

    private var color: Color {
        if remainingSeconds <= 10 {
            return .red
        }
        if remainingSeconds <= 30 {
            return .orange
        }
        return .purple
    }

    var body: some View {
        Label(QuizTimer.formattedTime(remainingSeconds), systemImage: "clock.fill")
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        )
    }
}

private struct AnswerOptionView: View {
    let answer: TriviaAnswerChoice
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(answer.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .accessibilityHidden(true)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isSelected ? Color.purple : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.purple.opacity(0.12) : Color.secondary.opacity(0.08))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.purple : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(answer.text)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
