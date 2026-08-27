import Foundation

/// Injectable "now" so day/week boundaries and timer elapsed-time math are
/// testable without waiting on the real clock.
protocol CurrentDateProviding {
    func now() -> Date
}

struct SystemDateProvider: CurrentDateProviding {
    func now() -> Date { Date() }
}
