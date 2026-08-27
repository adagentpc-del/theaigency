import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var fieldFocused: Bool

    init(statsStore: StatsStore) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(statsStore: statsStore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        TextField("I need to...", text: $viewModel.taskText, axis: .vertical)
                            .font(Theme.Typography.action())
                            .lineLimit(1...4)
                            .focused($fieldFocused)
                            .submitLabel(.go)
                            .accessibilityIdentifier(A11yID.Home.taskField)
                            .accessibilityLabel("What do you need to start?")
                            .onSubmit(start)

                        Text("e.g. \(viewModel.currentPlaceholder)")
                            .font(Theme.Typography.caption())
                            .foregroundStyle(Theme.Color.inkSecondary)
                            .accessibilityHidden(true)
                    }

                    Button("START ME", action: start)
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!viewModel.canStart)
                        .opacity(viewModel.canStart ? 1 : 0.4)
                        .accessibilityIdentifier(A11yID.Home.startButton)

                    Spacer(minLength: Theme.Spacing.lg)

                    statsFooter
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.Color.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(settingsStore: coordinator.settingsStore, statsStore: coordinator.statsStore)
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                    .accessibilityIdentifier(A11yID.Home.settingsButton)
                }
            }
        }
        .onAppear { viewModel.startRotatingPlaceholders(reduceMotion: reduceMotion) }
        .onDisappear { viewModel.stopRotatingPlaceholders() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("What do you need to start?")
                .font(.system(.title, design: .default).weight(.bold))
                .accessibilityAddTraits(.isHeader)

            Text("Don't give me the whole plan. Just tell me the thing.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Color.inkSecondary)
        }
    }

    private var statsFooter: some View {
        StatsSummaryView(summaryText: viewModel.statsSummaryText)
    }

    private func start() {
        guard viewModel.canStart else { return }
        fieldFocused = false
        let text = viewModel.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        coordinator.beginStarter(for: text)
    }
}

#Preview {
    NavigationStack {
        HomeView(statsStore: StatsStore())
    }
    .environmentObject(AppCoordinator())
}
