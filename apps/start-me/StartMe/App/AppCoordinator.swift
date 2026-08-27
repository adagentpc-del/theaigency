import Foundation

/// Owns the app's single linear flow and its shared local services. Start Me
/// deliberately has no navigation stack to manage — one screen is visible at
/// a time, and moving forward/back is just changing `screen`.
@MainActor
final class AppCoordinator: ObservableObject {
    @Published private(set) var screen: AppScreen = .home

    let engine: TaskStarterEngine
    let statsStore: StatsStore
    let settingsStore: SettingsStore

    init(
        engine: TaskStarterEngine = TaskStarterEngine(),
        statsStore: StatsStore = StatsStore(),
        settingsStore: SettingsStore = SettingsStore()
    ) {
        self.engine = engine
        self.statsStore = statsStore
        self.settingsStore = settingsStore
    }

    /// TYPE THE THING -> home hands off the raw text; the starter action
    /// itself is computed by `StarterViewModel` from `engine`.
    func beginStarter(for input: String) {
        screen = .starter(originalInput: input)
    }

    /// Tapping "START 60 SECONDS". This is the moment a "start" is recorded
    /// — Start Me counts starts, not completions.
    func beginInitialTimer(contextLabel: String) {
        statsStore.recordStart()
        screen = .timer(session: .initial(), contextLabel: contextLabel)
    }

    func timerCompleted(session: TimerSession, contextLabel: String) {
        let context: CompletionContext = session.kind == .initial ? .initial : .continuation
        screen = .completion(context: context, contextLabel: contextLabel)
    }

    /// "KEEP GOING" / "ANOTHER 5".
    func keepGoing(contextLabel: String) {
        statsStore.recordContinued()
        screen = .timer(session: .continuation(), contextLabel: contextLabel)
    }

    /// "I'M DONE" / "I STOPPED" / "DONE" — all three return home. Stopping
    /// is never treated as failure; the user already started.
    func returnHome() {
        screen = .home
    }
}
