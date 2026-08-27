import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel: TimerViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let contextLabel: String
    private let haptics: HapticsPlayer

    static let microcopy = [
        "Just this.",
        "You already started.",
        "Keep moving.",
        "Don't think ahead.",
        "One minute."
    ]

    @State private var microcopyIndex = 0

    init(session: TimerSession, contextLabel: String, hapticsEnabled: Bool) {
        _viewModel = StateObject(wrappedValue: TimerViewModel(session: session))
        self.contextLabel = contextLabel
        self.haptics = HapticsPlayer(isEnabled: hapticsEnabled)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Text(contextLabel)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Text(viewModel.formattedTime)
                .font(Theme.Typography.timer())
                .monospacedDigit()
                .foregroundStyle(Theme.Color.ink)
                .accessibilityIdentifier(A11yID.Timer.countdown)
                .accessibilityLabel("\(viewModel.remainingSeconds) seconds remaining")

            Text(microcopyLine)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Color.inkSecondary)
                .accessibilityIdentifier(A11yID.Timer.microcopy)
                .animation(reduceMotion ? nil : .easeInOut, value: microcopyIndex)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background)
        .onAppear {
            haptics.play(.timerStart)
            viewModel.onComplete = {
                haptics.play(.timerComplete)
                coordinator.timerCompleted(session: viewModel.session, contextLabel: contextLabel)
            }
            viewModel.start()
            startMicrocopyRotation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refreshFromWallClock()
            }
        }
    }

    private var microcopyLine: String {
        Self.microcopy[microcopyIndex % Self.microcopy.count]
    }

    private func startMicrocopyRotation() {
        guard !reduceMotion else { return }
        Task {
            while !Task.isCancelled && !viewModel.isComplete {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled else { return }
                microcopyIndex += 1
            }
        }
    }
}

#Preview {
    TimerView(session: .initial(), contextLabel: "Put your shoes on.", hapticsEnabled: true)
        .environmentObject(AppCoordinator())
}
