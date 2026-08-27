import SwiftUI

struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch coordinator.screen {
            case .home:
                HomeView(statsStore: coordinator.statsStore)

            case .starter(let originalInput):
                StarterView(originalInput: originalInput, engine: coordinator.engine)

            case .timer(let session, let contextLabel):
                TimerView(
                    session: session,
                    contextLabel: contextLabel,
                    hapticsEnabled: coordinator.settingsStore.hapticsEnabled
                )

            case .completion(let context, let contextLabel):
                CompletionView(context: context, contextLabel: contextLabel)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: coordinator.screen)
    }
}

#Preview {
    RootView()
        .environmentObject(AppCoordinator())
}
