import Foundation

/// Local-only aggregate stats: how many times the user *started* something.
/// Deliberately does not store task text — only per-day counts and a
/// continuation counter. See docs/PRIVACY_DATA_MAP.md.
final class StatsStore {
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let dateProvider: CurrentDateProviding

    private static let dayCountsKey = "startme.stats.dayCounts.v1"
    private static let continuedCountKey = "startme.stats.continuedCount.v1"

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = Calendar(identifier: .gregorian),
        dateProvider: CurrentDateProviding = SystemDateProvider()
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.dateProvider = dateProvider
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func dayKey(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private var dayCounts: [String: Int] {
        get {
            guard
                let data = defaults.data(forKey: Self.dayCountsKey),
                let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
            else {
                return [:]
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Self.dayCountsKey)
        }
    }

    /// Records one "start" (a tap on START 60 SECONDS) against today.
    func recordStart() {
        let key = dayKey(for: dateProvider.now())
        var counts = dayCounts
        counts[key, default: 0] += 1
        dayCounts = counts
    }

    /// Records one "Keep going" continuation beyond the initial 60 seconds.
    func recordContinued() {
        defaults.set(defaults.integer(forKey: Self.continuedCountKey) + 1, forKey: Self.continuedCountKey)
    }

    var totalStarts: Int {
        dayCounts.values.reduce(0, +)
    }

    var continuedCount: Int {
        defaults.integer(forKey: Self.continuedCountKey)
    }

    var startsToday: Int {
        dayCounts[dayKey(for: dateProvider.now())] ?? 0
    }

    /// Starts across the trailing 7 days (today included).
    var startsThisWeek: Int {
        let counts = dayCounts
        let today = dateProvider.now()
        return (0..<7).reduce(0) { total, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return total }
            return total + (counts[dayKey(for: day)] ?? 0)
        }
    }

    /// Distinct days with at least one start in the trailing 7 days. Used for
    /// the no-shame "N days with at least one start this week" framing —
    /// never a breakable streak counter.
    var daysActiveThisWeek: Int {
        let counts = dayCounts
        let today = dateProvider.now()
        return (0..<7).reduce(0) { total, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return total }
            return total + ((counts[dayKey(for: day)] ?? 0) > 0 ? 1 : 0)
        }
    }

    /// Settings > "Clear Local Data". Wipes every stat back to zero.
    func clearAllData() {
        defaults.removeObject(forKey: Self.dayCountsKey)
        defaults.removeObject(forKey: Self.continuedCountKey)
    }
}
