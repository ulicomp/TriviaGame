import SwiftUI

struct QuizView: View {
    let questions: [PreparedTriviaQuestion]
    @Binding var currentQuestionIndex: Int
    @Binding var selectedAnswerIDs: [PreparedTriviaQuestion.ID: TriviaAnswerChoice.ID]
    let onChangeOptions: () -> Void

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
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                .font(.headline)

            ProgressView(value: progress)
                .tint(.purple)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quiz progress")
        .accessibilityValue("Question \(currentQuestionIndex + 1) of \(questions.count)")
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
                Button("Submit Quiz") {}
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    .accessibilityHint("Quiz submission will be added in the next pass")
            }
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
