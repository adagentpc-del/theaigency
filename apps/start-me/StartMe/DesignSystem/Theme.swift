import SwiftUI

/// Start Me's visual language: modern, minimal, editorial, high-contrast,
/// subtly playful. Colors lean on semantic system colors (automatic
/// light/dark, automatic contrast) plus a single custom accent — "Ignition",
/// a warm ember/orange representing movement and starting, not the
/// purple/neon "AI product" look.
enum Theme {
    enum Color {
        static let accent = SwiftUI.Color.accentColor
        static let background = SwiftUI.Color(uiColor: .systemBackground)
        static let secondaryBackground = SwiftUI.Color(uiColor: .secondarySystemBackground)
        static let ink = SwiftUI.Color.primary
        static let inkSecondary = SwiftUI.Color.secondary
        static let onAccent = SwiftUI.Color.white
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
    }

    enum Radius {
        static let control: CGFloat = 16
        static let card: CGFloat = 20
    }

    enum Typography {
        static func headline() -> Font { .system(.headline, design: .default).weight(.semibold) }
        static func body() -> Font { .system(.body, design: .default) }
        static func caption() -> Font { .system(.subheadline, design: .default) }
        static func action() -> Font { .system(.largeTitle, design: .default).weight(.bold) }
        static func timer() -> Font { .system(size: 88, weight: .bold, design: .rounded) }
        static func button() -> Font { .system(.headline, design: .default).weight(.bold) }
    }

    /// Minimum tap target per accessibility guidance.
    static let minimumTapTarget: CGFloat = 44
}

/// A large, high-contrast, full-width primary call-to-action button.
struct PrimaryButtonStyle: ButtonStyle {
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.button())
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.minimumTapTarget + 12)
            .foregroundStyle(isProminent ? Theme.Color.onAccent : Theme.Color.ink)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(isProminent ? Theme.Color.accent : Theme.Color.secondaryBackground)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

/// A quieter text-style control for secondary actions ("Make it even
/// smaller", "Give me a different start").
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline())
            .foregroundStyle(Theme.Color.ink)
            .frame(minHeight: Theme.minimumTapTarget)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.Color.inkSecondary.opacity(0.25), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
