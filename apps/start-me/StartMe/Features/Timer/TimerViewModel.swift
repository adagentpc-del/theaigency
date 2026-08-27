import Foundation
import Combine

/// Accurate elapsed-time-based countdown. Remaining time is always
/// recomputed from a fixed `startDate`, not decremented tick-by-tick, so it
/// stays correct through SwiftUI state churn and short foreground/background
/// interruptions — call `refreshFromWallClock()` when the app returns to the
/// foreground to force an immediate recompute.
@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isComplete: Bool = false

    let session: TimerSession
    private let dateProvider: CurrentDateProviding
    private var startDate: Date?
    private var ticker: AnyCancellable?
    var onComplete: (() -> Void)?

    init(session: TimerSession, dateProvider: CurrentDateProviding = SystemDateProvider()) {
        self.session = session
        self.dateProvider = dateProvider
        self.remainingSeconds = Int(session.duration)
    }

    func start() {
        guard startDate == nil else { return }
        startDate = dateProvider.now()
        isComplete = false
        ticker = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
        tick()
    }

    /// Recomputes remaining time immediately from the wall clock. Call this
    /// on scenePhase becoming `.active` so a backgrounded/relaunched timer
    /// is instantly correct rather than waiting for the next tick.
    func refreshFromWallClock() {
        tick()
    }

    func stopTicking() {
        ticker?.cancel()
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func tick() {
        guard let startDate else { return }
        let elapsed = dateProvider.now().timeIntervalSince(startDate)
        let remaining = max(0, session.duration - elapsed)
        remainingSeconds = Int(remaining.rounded(.up))
        if remaining <= 0, !isComplete {
            isComplete = true
            ticker?.cancel()
            onComplete?()
        }
    }
}
