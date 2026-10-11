import SwiftUI

enum TriviaTheme {
    static let primary = Color(red: 0.36, green: 0.16, blue: 0.82)
    static let primaryDeep = Color(red: 0.22, green: 0.08, blue: 0.58)
    static let accent = Color(red: 0.72, green: 0.22, blue: 0.88)
    static let background = Color(red: 0.97, green: 0.96, blue: 1.0)
    static let backgroundWarm = Color(red: 1.0, green: 0.99, blue: 0.98)
    static let surface = Color.white
    static let surfaceTint = Color(red: 0.96, green: 0.94, blue: 1.0)
    static let textPrimary = Color(red: 0.12, green: 0.10, blue: 0.22)
    static let textSecondary = Color(red: 0.39, green: 0.36, blue: 0.48)
    static let success = Color(red: 0.10, green: 0.61, blue: 0.39)
    static let error = Color(red: 0.86, green: 0.24, blue: 0.30)
    static let warning = Color(red: 0.92, green: 0.52, blue: 0.10)
    static let border = Color(red: 0.86, green: 0.82, blue: 0.95)

    static let brandGradient = LinearGradient(
        colors: [primaryDeep, primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let progressGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardCornerRadius: CGFloat = 24
    static let controlCornerRadius: CGFloat = 16
    static let horizontalPadding: CGFloat = 20
}

struct TriviaBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            decoration
            content
        }
        .foregroundStyle(TriviaTheme.textPrimary)
        .accessibilityElement(children: .contain)
    }

    private var decoration: some View {
        ZStack {
            LinearGradient(
                colors: [TriviaTheme.background, TriviaTheme.backgroundWarm],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(TriviaTheme.accent.opacity(0.10))
                .frame(width: 290, height: 290)
                .blur(radius: 2)
                .offset(x: 150, y: -290)

            Circle()
                .fill(TriviaTheme.primary.opacity(0.07))
                .frame(width: 220, height: 220)
                .offset(x: -155, y: 330)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

struct TriviaGameBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            decoration
            content
        }
        .accessibilityElement(children: .contain)
    }

    private var decoration: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TriviaTheme.primaryDeep,
                    Color(red: 0.30, green: 0.10, blue: 0.72),
                    TriviaTheme.primary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(TriviaTheme.accent.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 8)
                .offset(x: 170, y: -280)

            Circle()
                .fill(Color.white.opacity(0.055))
                .frame(width: 250, height: 250)
                .offset(x: -165, y: 350)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

struct TriviaCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TriviaTheme.surface, in: RoundedRectangle(cornerRadius: TriviaTheme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: TriviaTheme.cardCornerRadius)
                    .stroke(TriviaTheme.border.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: TriviaTheme.primaryDeep.opacity(0.10), radius: 18, y: 9)
    }
}

struct TriviaProgressBar: View {
    let progress: Double
    var onDarkBackground = false

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(onDarkBackground ? Color.white.opacity(0.22) : TriviaTheme.border.opacity(0.55))

                Capsule()
                    .fill(
                        onDarkBackground
                            ? LinearGradient(
                                colors: [.white, Color(red: 0.88, green: 0.76, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : TriviaTheme.progressGradient
                    )
                    .frame(width: geometry.size.width * clampedProgress)
            }
        }
        .frame(height: 9)
        .animation(.easeInOut(duration: 0.28), value: clampedProgress)
        .accessibilityHidden(true)
    }
}

struct TriviaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 18)
            .background(TriviaTheme.brandGradient, in: RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius))
            .shadow(
                color: TriviaTheme.primary.opacity(configuration.isPressed ? 0.12 : 0.25),
                radius: configuration.isPressed ? 4 : 10,
                y: configuration.isPressed ? 2 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct TriviaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(TriviaTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background(TriviaTheme.surface.opacity(configuration.isPressed ? 0.75 : 0.96))
            .overlay {
                RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
                    .stroke(TriviaTheme.border, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct TriviaGamePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(TriviaTheme.primaryDeep)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 18)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.86 : 1),
                in: RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct TriviaGameSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.22 : 0.14),
                in: RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TriviaTheme.controlCornerRadius)
                    .stroke(Color.white.opacity(0.34), lineWidth: 1.5)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct TriviaCapsuleLabel: View {
    let title: String
    let systemImage: String?
    var color = TriviaTheme.primary

    var body: some View {
        Label {
            Text(title)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}
