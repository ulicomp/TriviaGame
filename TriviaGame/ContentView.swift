import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var configuration = TriviaConfiguration()
    @State private var questions: [TriviaQuestion] = []
    @State private var preparedQuestions: [PreparedTriviaQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIDs: [PreparedTriviaQuestion.ID: TriviaAnswerChoice.ID] = [:]
    @State private var appState = AppState.options(.idle)
    @State private var quizSessionID: UUID?
    @State private var quizDeadline: Date?
    @State private var remainingSeconds = 0
    @State private var timerTask: Task<Void, Never>?

    private let triviaService = TriviaService()

    var body: some View {
        Group {
            switch appState {
            case .options(let loadState):
                optionsView(loadState: loadState)
            case .activeQuiz:
                QuizView(
                    questions: preparedQuestions,
                    currentQuestionIndex: $currentQuestionIndex,
                    selectedAnswerIDs: $selectedAnswerIDs,
                    remainingSeconds: remainingSeconds,
                    unansweredCount: unansweredCount,
                    onSubmit: {
                        submitQuiz()
                    },
                    onChangeOptions: returnToOptions
                )
            case .completed(let result):
                ResultsView(
                    result: result,
                    onReviewAnswers: beginReview,
                    onPlayAgain: {
                        Task {
                            await loadQuiz(context: .replay)
                        }
                    },
                    onChangeOptions: returnToOptions
                )
            case .reviewing(let result):
                QuizReviewView(
                    questions: preparedQuestions,
                    selectedAnswerIDs: selectedAnswerIDs,
                    onBackToResults: {
                        returnToResults(result: result)
                    }
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
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
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

        invalidateTimer()
        resetQuizData()
        appState = context == .options ? .options(.loading) : .replaying

        do {
            questions = try await triviaService.fetchQuestions(configuration: configuration)
            preparedQuestions = try PreparedTriviaQuestion.prepare(questions)
            selectedAnswerIDs = [:]
            currentQuestionIndex = 0
            beginActiveQuiz()
        } catch {
            invalidateTimer()
            resetQuizData()
            appState = context == .options
                ? .options(.failure(error.localizedDescription))
                : .replayFailure(error.localizedDescription)
        }
    }

    private func returnToOptions() {
        invalidateTimer()
        resetQuizData()
        appState = .options(.idle)
    }

    private func submitQuiz(expectedSessionID: UUID? = nil) {
        guard case .activeQuiz = appState,
              let activeSessionID = quizSessionID,
              expectedSessionID == nil || expectedSessionID == activeSessionID else {
            return
        }

        let result = QuizResult.calculate(
            questions: preparedQuestions,
            selectedAnswerIDs: selectedAnswerIDs
        )

        invalidateTimer()
        appState = .completed(result)
    }

    private func beginActiveQuiz() {
        let duration = QuizTimer.duration(forQuestionCount: preparedQuestions.count)
        guard duration > 0 else {
            appState = .options(.failure("The quiz did not contain any questions."))
            return
        }

        let sessionID = UUID()
        quizSessionID = sessionID
        remainingSeconds = duration
        quizDeadline = Date().addingTimeInterval(TimeInterval(duration))
        appState = .activeQuiz

        if scenePhase == .active {
            startTimer(for: sessionID)
        }
    }

    private func startTimer(for sessionID: UUID) {
        timerTask?.cancel()

        guard case .activeQuiz = appState,
              quizSessionID == sessionID,
              quizDeadline != nil else {
            timerTask = nil
            return
        }

        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                guard case .activeQuiz = appState,
                      quizSessionID == sessionID,
                      let deadline = quizDeadline else {
                    return
                }

                let updatedRemainingSeconds = QuizTimer.remainingSeconds(until: deadline)
                remainingSeconds = updatedRemainingSeconds

                if updatedRemainingSeconds == 0 {
                    submitQuiz(expectedSessionID: sessionID)
                    return
                }

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            resumeTimerIfNeeded()
        case .inactive, .background:
            pauseTimerTask()
        @unknown default:
            pauseTimerTask()
        }
    }

    private func resumeTimerIfNeeded() {
        guard case .activeQuiz = appState,
              let sessionID = quizSessionID,
              let deadline = quizDeadline else {
            return
        }

        let updatedRemainingSeconds = QuizTimer.remainingSeconds(until: deadline)
        remainingSeconds = updatedRemainingSeconds

        if updatedRemainingSeconds == 0 {
            submitQuiz(expectedSessionID: sessionID)
        } else {
            startTimer(for: sessionID)
        }
    }

    private func pauseTimerTask() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func invalidateTimer() {
        pauseTimerTask()
        quizSessionID = nil
        quizDeadline = nil
        remainingSeconds = 0
    }

    private func beginReview() {
        guard case .completed(let result) = appState else { return }
        appState = .reviewing(result)
    }

    private func returnToResults(result: QuizResult) {
        guard case .reviewing = appState else { return }
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
    case reviewing(QuizResult)
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
