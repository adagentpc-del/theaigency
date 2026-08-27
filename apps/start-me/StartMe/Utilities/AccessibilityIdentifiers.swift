import Foundation

/// Central registry of accessibility identifiers used by both views and
/// tests, so identifiers can't drift out of sync between the two.
enum A11yID {
    enum Home {
        static let taskField = "home.taskField"
        static let startButton = "home.startButton"
        static let statsSummary = "home.statsSummary"
        static let settingsButton = "home.settingsButton"
    }

    enum Starter {
        static let primaryAction = "starter.primaryAction"
        static let reassurance = "starter.reassurance"
        static let startTimerButton = "starter.startTimerButton"
        static let makeSmallerButton = "starter.makeSmallerButton"
        static let differentStartButton = "starter.differentStartButton"
    }

    enum Timer {
        static let countdown = "timer.countdown"
        static let microcopy = "timer.microcopy"
    }

    enum Completion {
        static let title = "completion.title"
        static let keepGoingButton = "completion.keepGoingButton"
        static let doneButton = "completion.doneButton"
        static let stoppedButton = "completion.stoppedButton"
        static let anotherFiveButton = "completion.anotherFiveButton"
    }

    enum Settings {
        static let hapticsToggle = "settings.hapticsToggle"
        static let clearDataButton = "settings.clearDataButton"
        static let privacyLink = "settings.privacyLink"
        static let supportLink = "settings.supportLink"
    }
}
