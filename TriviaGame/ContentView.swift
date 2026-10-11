import SwiftUI

struct ContentView: View {
    @State private var configuration = TriviaConfiguration()
    @State private var questions: [TriviaQuestion] = []
    @State private var loadState = LoadState.idle

    private let triviaService = TriviaService()

    var body: some View {
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
                            await startTrivia()
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

                statusSection
            }
            .navigationTitle("Trivia Game")
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch loadState {
        case .idle, .loading:
            EmptyView()
        case .success(let count):
            Section("Status") {
                Text("Loaded \(count) questions")
                    .foregroundStyle(.green)
            }
        case .failure(let message):
            Section("Error") {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    @MainActor
    private func startTrivia() async {
        guard !loadState.isLoading else { return }

        loadState = .loading

        do {
            questions = try await triviaService.fetchQuestions(configuration: configuration)
            loadState = .success(questions.count)
        } catch {
            questions = []
            loadState = .failure(error.localizedDescription)
        }
    }
}

private enum LoadState {
    case idle
    case loading
    case success(Int)
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
