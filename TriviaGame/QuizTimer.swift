import Foundation

enum QuizTimer {
    static let secondsPerQuestion = 30

    static func duration(forQuestionCount questionCount: Int) -> Int {
        max(questionCount, 0) * secondsPerQuestion
    }

    static func remainingSeconds(until deadline: Date, now: Date = .now) -> Int {
        max(0, Int(ceil(deadline.timeIntervalSince(now))))
    }

    static func formattedTime(_ seconds: Int) -> String {
        let clampedSeconds = max(seconds, 0)
        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    static func accessibilityDescription(_ seconds: Int) -> String {
        let clampedSeconds = max(seconds, 0)
        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60
        var parts: [String] = []

        if minutes > 0 {
            parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }

        if remainingSeconds > 0 || minutes == 0 {
            parts.append("\(remainingSeconds) \(remainingSeconds == 1 ? "second" : "seconds")")
        }

        return parts.joined(separator: " ") + " remaining"
    }
}
