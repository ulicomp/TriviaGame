import SwiftUI

struct ContentView: View {
    @State private var configuration = TriviaConfiguration()
    @State private var questions: [TriviaQuestion] = []
    @State private var preparedQuestions: [PreparedTriviaQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIDs: [PreparedTriviaQuestion.ID: TriviaAnswerChoice.ID] = [:]
    @State private var appState = AppState.options(.idle)

    private let triviaService = TriviaService()

    var body: some View {
        switch appState {
        case .options(let loadState):
            optionsView(loadState: loadState)
        case .activeQuiz:
            QuizView(
                questions: preparedQuestions,
                currentQuestionIndex: $currentQuestionIndex,
                selectedAnswerIDs: $selectedAnswerIDs,
                unansweredCount: unansweredCount,
                onSubmit: submitQuiz,
                onChangeOptions: returnToOptions
            )
        case .completed(let result):
            ResultsView(
                result: result,
                onPlayAgain: {
                    Task {
                        await loadQuiz(context: .replay)
                    }
                },
                onChangeOptions: returnToOptions
            )
        case .replaying:
            ReplayStatusView(
                errorMessage: nil,
                onRetry: {},
                onChangeOptions: returnToOptions
            )
        case .replayFailure(let message):
            ReplayStatusView(
                errorMessage: message,
                onRetry: {
                    Task {
                        await loadQuiz(context: .replay)
                    }
                },
                onChangeOptions: returnToOptions
            )
        }
    }

    private func optionsView(loadState: LoadState) -> some View {
        NavigationStack {
            Form {
                Section("Quiz Options") {
                    Stepper(
                        "Number of Questions: \(configuration.questionCount)",
                        value: $configuration.questionCount,
                        in: TriviaConfiguration.questionCountRange
                    )

                    Picker("Category", selection: $configuration.category) {
                        ForEach(TriviaCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

                    Picker("Difficulty", selection: $configuration.difficulty) {
                        ForEach(TriviaDifficulty.allCases) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }

                    Picker("Question Type", selection: $configuration.questionType) {
                        ForEach(TriviaQuestionType.allCases) { questionType in
                            Text(questionType.displayName).tag(questionType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        Task {
                            await loadQuiz(context: .options)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if loadState.isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text(loadState.isLoading ? "Loading..." : "Start Trivia")
                            Spacer()
                        }
                    }
                    .disabled(loadState.isLoading)
                }

                statusSection(loadState: loadState)
            }
            .navigationTitle("Trivia Game")
        }
    }

    @ViewBuilder
    private func statusSection(loadState: LoadState) -> some View {
        switch loadState {
        case .idle, .loading:
            EmptyView()
        case .failure(let message):
            Section("Error") {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    private var unansweredCount: Int {
        preparedQuestions.reduce(into: 0) { count, question in
            guard let selectedAnswerID = selectedAnswerIDs[question.id],
                  question.answerChoices.contains(where: { $0.id == selectedAnswerID }) else {
                count += 1
                return
            }
        }
    }

    @MainActor
    private func loadQuiz(context: LoadContext) async {
        guard canBeginLoading(context: context) else { return }

        resetQuizData()
        appState = context == .options ? .options(.loading) : .replaying

        do {
            questions = try await triviaService.fetchQuestions(configuration: configuration)
            preparedQuestions = try PreparedTriviaQuestion.prepare(questions)
            selectedAnswerIDs = [:]
            currentQuestionIndex = 0
            appState = .activeQuiz
        } catch {
            resetQuizData()
            appState = context == .options
                ? .options(.failure(error.localizedDescription))
                : .replayFailure(error.localizedDescription)
        }
    }

    private func returnToOptions() {
        resetQuizData()
        appState = .options(.idle)
    }

    private func submitQuiz() {
        guard case .activeQuiz = appState else { return }

        let result = QuizResult.calculate(
            questions: preparedQuestions,
            selectedAnswerIDs: selectedAnswerIDs
        )
        appState = .completed(result)
    }

    private func canBeginLoading(context: LoadContext) -> Bool {
        switch (context, appState) {
        case (.options, .options(let loadState)):
            !loadState.isLoading
        case (.replay, .completed), (.replay, .replayFailure):
            true
        default:
            false
        }
    }

    private func resetQuizData() {
        questions = []
        preparedQuestions = []
        selectedAnswerIDs = [:]
        currentQuestionIndex = 0
    }
}

private enum AppState {
    case options(LoadState)
    case activeQuiz
    case completed(QuizResult)
    case replaying
    case replayFailure(String)
}

private enum LoadContext: Equatable {
    case options
    case replay
}

private enum LoadState {
    case idle
    case loading
    case failure(String)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

#Preview {
    ContentView()
}
