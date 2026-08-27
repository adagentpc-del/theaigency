import Foundation

enum TimerKind: Equatable {
    case initial
    case continuation
}

/// The configuration for one run of the countdown timer. `initial` is the
/// core 60-second start; `continuation` is the optional 5-minute momentum
/// extension after "Keep going".
struct TimerSession: Equatable {
    let kind: TimerKind
    let duration: TimeInterval

    static func initial() -> TimerSession {
        TimerSession(kind: .initial, duration: 60)
    }

    static func continuation() -> TimerSession {
        TimerSession(kind: .continuation, duration: 300)
    }
}
