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
        .preferredColorScheme(.light)
    }

    private func optionsView(loadState: LoadState) -> some View {
        NavigationStack {
            TriviaBackground {
                ScrollView {
                    VStack(spacing: 24) {
                        optionsHero

                        TriviaCard {
                            VStack(spacing: 4) {
                                Text("BUILD YOUR QUIZ")
                                    .font(.caption.weight(.bold))
                                    .tracking(1.4)
                                    .foregroundStyle(TriviaTheme.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 8)

                                QuestionCountRow(questionCount: $configuration.questionCount)

                                Divider().overlay(TriviaTheme.border.opacity(0.7))

                                Menu {
                                    Picker("Category", selection: $configuration.category) {
                                        ForEach(TriviaCategory.allCases) { category in
                                            Text(category.displayName).tag(category)
                                        }
                                    }
                                } label: {
                                    ConfigurationRow(
                                        icon: "square.grid.2x2.fill",
                                        title: "Category",
                                        value: configuration.category.displayName
                                    )
                                }

                                Divider().overlay(TriviaTheme.border.opacity(0.7))

                                Menu {
                                    Picker("Difficulty", selection: $configuration.difficulty) {
                                        ForEach(TriviaDifficulty.allCases) { difficulty in
                                            Text(difficulty.displayName).tag(difficulty)
                                        }
                                    }
                                } label: {
                                    ConfigurationRow(
                                        icon: "chart.bar.fill",
                                        title: "Difficulty",
                                        value: configuration.difficulty.displayName
                                    )
                                }

                                Divider().overlay(TriviaTheme.border.opacity(0.7))

                                Menu {
                                    Picker("Question Type", selection: $configuration.questionType) {
                                        ForEach(TriviaQuestionType.allCases) { questionType in
                                            Text(questionType.displayName).tag(questionType)
                                        }
                                    }
                                } label: {
                                    ConfigurationRow(
                                        icon: "list.bullet.rectangle.fill",
                                        title: "Type",
                                        value: configuration.questionType.displayName
                                    )
                                }
                            }
                        }

                        if case .failure(let message) = loadState {
                            InlineErrorCard(message: message)
                        }

                        Button {
                            Task {
                                await loadQuiz(context: .options)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if loadState.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Preparing your quiz…")
                                } else {
                                    Image(systemName: loadState.isFailure ? "arrow.clockwise" : "play.fill")
                                    Text(loadState.isFailure ? "Try Again" : "Start Trivia")
                                }
                            }
                        }
                        .buttonStyle(TriviaPrimaryButtonStyle())
                        .disabled(loadState.isLoading)
                        .opacity(loadState.isLoading ? 0.78 : 1)
                    }
                    .padding(.horizontal, TriviaTheme.horizontalPadding)
                    .padding(.top, 22)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var optionsHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TriviaTheme.brandGradient)
                    .frame(width: 82, height: 82)
                    .shadow(color: TriviaTheme.primary.opacity(0.28), radius: 18, y: 9)

                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Trivia Quiz")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Put your knowledge to the test")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TriviaTheme.textSecondary)
            }
            .multilineTextAlignment(.center)
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

        let totalDuration = QuizTimer.duration(forQuestionCount: preparedQuestions.count)
        let completionTimeSeconds: Int
        if let quizDeadline {
            completionTimeSeconds = QuizTimer.elapsedSeconds(
                totalDuration: totalDuration,
                deadline: quizDeadline
            )
        } else {
            completionTimeSeconds = min(
                max(totalDuration - remainingSeconds, 0),
                totalDuration
            )
        }

        let result = QuizResult.calculate(
            questions: preparedQuestions,
            selectedAnswerIDs: selectedAnswerIDs,
            completionTimeSeconds: completionTimeSeconds
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

private struct QuestionCountRow: View {
    @Binding var questionCount: Int

    var body: some View {
        HStack(spacing: 14) {
            configurationIcon

            VStack(alignment: .leading, spacing: 3) {
                Text("Questions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TriviaTheme.textSecondary)
                Text("\(questionCount)")
                    .font(.body.weight(.bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
            }
            .accessibilityHidden(true)

            Spacer(minLength: 8)

            Stepper(
                "Number of questions",
                value: $questionCount,
                in: TriviaConfiguration.questionCountRange
            )
            .labelsHidden()
            .tint(TriviaTheme.primary)
            .accessibilityLabel("Number of questions")
            .accessibilityValue("\(questionCount)")
        }
        .padding(.vertical, 10)
    }

    private var configurationIcon: some View {
        Image(systemName: "number.circle.fill")
            .font(.title3.weight(.semibold))
            .foregroundStyle(TriviaTheme.primary)
            .frame(width: 42, height: 42)
            .background(TriviaTheme.surfaceTint, in: RoundedRectangle(cornerRadius: 13))
            .accessibilityHidden(true)
    }
}

private struct ConfigurationRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(TriviaTheme.primary)
                .frame(width: 42, height: 42)
                .background(TriviaTheme.surfaceTint, in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TriviaTheme.textSecondary)

                Text(value)
                    .font(.body.weight(.bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(TriviaTheme.primary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityHint("Double tap to change")
    }
}

private struct InlineErrorCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(TriviaTheme.error)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Unable to prepare quiz")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(TriviaTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TriviaTheme.error.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(TriviaTheme.error.opacity(0.28), lineWidth: 1)
        }
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

    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}

#Preview {
    ContentView()
}
