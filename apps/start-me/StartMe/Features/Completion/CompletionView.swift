import SwiftUI

struct CompletionView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    let context: CompletionContext
    let contextLabel: String

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Text(title)
                .font(Theme.Typography.action())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(A11yID.Completion.title)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                switch context {
                case .initial:
                    Button("KEEP GOING") {
                        coordinator.keepGoing(contextLabel: contextLabel)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier(A11yID.Completion.keepGoingButton)

                    Button("I'M DONE") {
                        coordinator.returnHome()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(A11yID.Completion.doneButton)

                    Button("I STOPPED") {
                        coordinator.returnHome()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(A11yID.Completion.stoppedButton)

                case .continuation:
                    Button("ANOTHER 5") {
                        coordinator.keepGoing(contextLabel: contextLabel)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier(A11yID.Completion.anotherFiveButton)

                    Button("DONE") {
                        coordinator.returnHome()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(A11yID.Completion.doneButton)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background)
    }

    private var title: String {
        switch context {
        case .initial: return "You started."
        case .continuation: return "Still going?"
        }
    }

    private var subtitle: String {
        switch context {
        case .initial: return "That was the whole point."
        case .continuation: return "You can keep going, or call it here. Either way, you still started."
        }
    }
}

#Preview {
    CompletionView(context: .initial, contextLabel: "Put your shoes on.")
        .environmentObject(AppCoordinator())
}
