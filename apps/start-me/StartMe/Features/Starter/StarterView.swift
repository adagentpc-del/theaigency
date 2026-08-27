import SwiftUI

struct StarterView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel: StarterViewModel

    init(originalInput: String, engine: TaskStarterEngine) {
        _viewModel = StateObject(wrappedValue: StarterViewModel(originalInput: originalInput, engine: engine))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Your only job:")
                .font(Theme.Typography.headline())
                .foregroundStyle(Theme.Color.inkSecondary)

            Text(viewModel.displayedActionText)
                .font(Theme.Typography.action())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(A11yID.Starter.primaryAction)
                .accessibilityAddTraits(.isHeader)

            if let reassurance = viewModel.reassurance {
                Text(reassurance)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Color.inkSecondary)
                    .accessibilityIdentifier(A11yID.Starter.reassurance)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Button("START 60 SECONDS") {
                    coordinator.beginInitialTimer(contextLabel: viewModel.displayedActionText)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier(A11yID.Starter.startTimerButton)

                VStack(spacing: Theme.Spacing.sm) {
                    if viewModel.canMakeSmaller {
                        Button("Make it even smaller", action: viewModel.makeSmaller)
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier(A11yID.Starter.makeSmallerButton)
                    }

                    if viewModel.canOfferDifferentStart {
                        Button("Give me a different start", action: viewModel.requestDifferentStart)
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier(A11yID.Starter.differentStartButton)
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Color.background)
    }
}

#Preview {
    StarterView(originalInput: "clean my entire apartment", engine: TaskStarterEngine())
        .environmentObject(AppCoordinator())
}
