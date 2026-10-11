import SwiftUI

struct ResultsView: View {
    let result: QuizResult
    let onReviewAnswers: () -> Void
    let onPlayAgain: () -> Void
    let onChangeOptions: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Quiz Complete!")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)

                    VStack(spacing: 12) {
                        Text("\(result.correctCount) / \(result.totalCount)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)
                            .accessibilityLabel("Score")
                            .accessibilityValue("\(result.correctCount) out of \(result.totalCount)")

                        Text("\(result.percentage)%")
                            .font(.title2.weight(.semibold))
                            .accessibilityLabel("Percentage")
                            .accessibilityValue("\(result.percentage) percent")

                        ProgressView(
                            value: Double(result.correctCount),
                            total: Double(max(result.totalCount, 1))
                        )
                        .tint(.purple)
                        .accessibilityHidden(true)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    )

                    VStack(spacing: 8) {
                        Text("\(result.correctCount) correct out of \(result.totalCount) questions")
                        Text("\(result.answeredCount) answered · \(result.unansweredCount) unanswered")
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        Button("Review Answers", action: onReviewAnswers)
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .frame(maxWidth: .infinity)
                            .accessibilityHint("Reviews each submitted answer and the correct answer")

                        Button("Play Again", action: onPlayAgain)
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            .accessibilityHint("Loads a new quiz using the same options")

                        Button("Change Options", action: onChangeOptions)
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            .accessibilityHint("Returns to the quiz options screen")
                    }
                }
                .padding()
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReplayStatusView: View {
    let errorMessage: String?
    let onRetry: () -> Void
    let onChangeOptions: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let errorMessage {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                        .accessibilityHidden(true)

                    Text("Unable to Load a New Quiz")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)

                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Try Again", action: onRetry)
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)

                    Button("Change Options", action: onChangeOptions)
                        .buttonStyle(.bordered)
                } else {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading a new quiz...")
                        .font(.headline)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .padding()
            .navigationTitle("Trivia Game")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
