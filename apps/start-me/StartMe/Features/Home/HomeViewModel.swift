import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var taskText: String = ""
    @Published private(set) var currentPlaceholderIndex: Int = 0

    private let statsStore: StatsStore
    private var placeholderTask: Task<Void, Never>?

    static let rotatingExamples = [
        "clean my kitchen",
        "answer emails",
        "start studying",
        "go to the gym",
        "do laundry",
        "pack for my trip",
        "work on my résumé",
        "file my taxes"
    ]

    init(statsStore: StatsStore) {
        self.statsStore = statsStore
    }

    var canStart: Bool {
        !taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var currentPlaceholder: String {
        Self.rotatingExamples[currentPlaceholderIndex % Self.rotatingExamples.count]
    }

    /// "You started 4 things today." / "17 starts this week." / a no-shame
    /// comeback line when there's nothing recent to report. Focuses on
    /// starts, never completions.
    var statsSummaryText: String {
        let today = statsStore.startsToday
        if today > 0 {
            return today == 1 ? "You started 1 thing today." : "You started \(today) things today."
        }
        let week = statsStore.startsThisWeek
        if week > 0 {
            return week == 1 ? "1 start this week." : "\(week) starts this week."
        }
        return "You came back. That counts."
    }

    func startRotatingPlaceholders(reduceMotion: Bool) {
        placeholderTask?.cancel()
        guard !reduceMotion else { return }
        placeholderTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_500_000_000)
                guard !Task.isCancelled else { return }
                self?.currentPlaceholderIndex += 1
            }
        }
    }

    func stopRotatingPlaceholders() {
        placeholderTask?.cancel()
        placeholderTask = nil
    }
}
