import SwiftUI

struct ResultsView: View {
    let result: QuizResult
    let onReviewAnswers: () -> Void
    let onPlayAgain: () -> Void
    let onChangeOptions: () -> Void

    private var encouragement: String {
        switch result.percentage {
        case 90...: "Outstanding!"
        case 70...: "Great work!"
        case 50...: "Nice work!"
        default: "Keep going!"
        }
    }

    var body: some View {
        NavigationStack {
            TriviaBackground {
                ScrollView {
                    VStack(spacing: 22) {
                        completionHeader
                        scoreCard
                        statistics
                        completionTimeCard
                        actions
                    }
                    .padding(.horizontal, TriviaTheme.horizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var completionHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TriviaTheme.brandGradient)
                    .frame(width: 78, height: 78)
                    .shadow(color: TriviaTheme.primary.opacity(0.25), radius: 16, y: 8)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text("Quiz Complete")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(TriviaTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(encouragement)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TriviaTheme.primary)
        }
        .multilineTextAlignment(.center)
    }

    private var scoreCard: some View {
        TriviaCard {
            VStack(spacing: 18) {
                ScoreRing(result: result)

                Text("\(result.correctCount) correct out of \(result.totalCount) questions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TriviaTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var statistics: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                statCards
            }

            VStack(spacing: 10) {
                statCards
            }
        }
    }

    private var completionTimeCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(TriviaTheme.primary)
                .frame(width: 42, height: 42)
                .background(TriviaTheme.surfaceTint, in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Completion Time")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TriviaTheme.textSecondary)
                Text(QuizTimer.formattedTime(result.completionTimeSeconds))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(TriviaTheme.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(TriviaTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(TriviaTheme.primary.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Completion time")
        .accessibilityValue(
            QuizTimer.durationAccessibilityDescription(result.completionTimeSeconds)
        )
    }

    @ViewBuilder
    private var statCards: some View {
        ResultStatCard(
            value: result.correctCount,
            label: "Correct",
            icon: "checkmark.circle.fill",
            color: TriviaTheme.success
        )
        ResultStatCard(
            value: result.answeredCount,
            label: "Answered",
            icon: "text.badge.checkmark",
            color: TriviaTheme.primary
        )
        ResultStatCard(
            value: result.unansweredCount,
            label: "Unanswered",
            icon: "minus.circle.fill",
            color: TriviaTheme.warning
        )
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: onPlayAgain) {
                Label("Play Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(TriviaPrimaryButtonStyle())
            .accessibilityHint("Loads a new quiz using the same options")

            Button(action: onReviewAnswers) {
                Label("Review Answers", systemImage: "doc.text.magnifyingglass")
            }
            .buttonStyle(TriviaSecondaryButtonStyle())
            .accessibilityHint("Reviews each submitted answer and the correct answer")

            Button(action: onChangeOptions) {
                Label("Change Options", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(TriviaSecondaryButtonStyle())
            .accessibilityHint("Returns to the quiz options screen")
        }
    }
}

private struct ScoreRing: View {
    let result: QuizResult

    private var progress: Double {
        guard result.totalCount > 0 else { return 0 }
        return Double(result.correctCount) / Double(result.totalCount)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(TriviaTheme.border.opacity(0.55), lineWidth: 13)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    TriviaTheme.progressGradient,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(result.correctCount) / \(result.totalCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(TriviaTheme.textPrimary)
                Text("\(result.percentage)%")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TriviaTheme.primary)
            }
        }
        .frame(width: 168, height: 168)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quiz score")
        .accessibilityValue(
            "\(result.correctCount) out of \(result.totalCount), \(result.percentage) percent"
        )
    }
}

private struct ResultStatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(TriviaTheme.textPrimary)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TriviaTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 104)
        .background(TriviaTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.20), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value)")
    }
}

struct ReplayStatusView: View {
    let errorMessage: String?
    let onRetry: () -> Void
    let onChangeOptions: () -> Void

    var body: some View {
        NavigationStack {
            TriviaBackground {
                VStack(spacing: 22) {
                    Spacer()

                    if let errorMessage {
                        errorContent(message: errorMessage)
                    } else {
                        loadingContent
                    }

                    Spacer()
                }
                .padding(TriviaTheme.horizontalPadding)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var loadingContent: some View {
        TriviaCard {
            VStack(spacing: 18) {
                ProgressView()
                    .controlSize(.large)
                    .tint(TriviaTheme.primary)
                Text("Preparing your quiz…")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Finding a fresh set of questions")
                    .font(.subheadline)
                    .foregroundStyle(TriviaTheme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private func errorContent(message: String) -> some View {
        TriviaCard {
            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 42))
                    .foregroundStyle(TriviaTheme.error)
                    .accessibilityHidden(true)

                Text("Unable to Load a New Quiz")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(TriviaTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Try Again", action: onRetry)
                    .buttonStyle(TriviaPrimaryButtonStyle())

                Button("Change Options", action: onChangeOptions)
                    .buttonStyle(TriviaSecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
    }
}
