import XCTest
@testable import StartMe

final class StatsStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var dateProvider: FakeDateProvider!
    private var store: StatsStore!

    override func setUp() {
        super.setUp()
        suiteName = "StatsStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        dateProvider = FakeDateProvider()
        store = StatsStore(defaults: defaults, dateProvider: dateProvider)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_freshStore_startsAtZero() {
        XCTAssertEqual(store.totalStarts, 0)
        XCTAssertEqual(store.startsToday, 0)
        XCTAssertEqual(store.startsThisWeek, 0)
        XCTAssertEqual(store.continuedCount, 0)
        XCTAssertEqual(store.daysActiveThisWeek, 0)
    }

    func test_recordStart_incrementsTodayAndTotal() {
        store.recordStart()
        store.recordStart()
        XCTAssertEqual(store.startsToday, 2)
        XCTAssertEqual(store.totalStarts, 2)
    }

    func test_recordContinued_incrementsContinuedCountOnly() {
        store.recordStart()
        store.recordContinued()
        XCTAssertEqual(store.continuedCount, 1)
        XCTAssertEqual(store.totalStarts, 1)
    }

    func test_dayBoundary_startsTodayResetsOnNewDay() {
        store.recordStart()
        XCTAssertEqual(store.startsToday, 1)

        dateProvider.advance(by: 60 * 60 * 24) // next day
        XCTAssertEqual(store.startsToday, 0, "a new day should not carry yesterday's count")
        XCTAssertEqual(store.totalStarts, 1, "but the total should still include it")
    }

    func test_weekBoundary_startsThisWeekIncludesTrailingSevenDaysOnly() {
        store.recordStart() // day 0
        dateProvider.advance(by: 60 * 60 * 24 * 10) // 10 days later, outside the 7-day window
        store.recordStart()
        XCTAssertEqual(store.startsThisWeek, 1, "the 10-day-old start should have rolled off the week window")
        XCTAssertEqual(store.totalStarts, 2)
    }

    func test_daysActiveThisWeek_countsDistinctDaysNotTotalStarts() {
        store.recordStart()
        store.recordStart()
        store.recordStart()
        XCTAssertEqual(store.daysActiveThisWeek, 1, "three starts on the same day is still one active day")

        dateProvider.advance(by: 60 * 60 * 24)
        store.recordStart()
        XCTAssertEqual(store.daysActiveThisWeek, 2)
    }

    func test_clearAllData_resetsEverything() {
        store.recordStart()
        store.recordContinued()
        store.clearAllData()
        XCTAssertEqual(store.totalStarts, 0)
        XCTAssertEqual(store.continuedCount, 0)
        XCTAssertEqual(store.startsToday, 0)
    }

    func test_persistsAcrossNewStoreInstances_simulatingRelaunch() {
        store.recordStart()
        store.recordStart()

        let relaunchedStore = StatsStore(defaults: defaults, dateProvider: dateProvider)
        XCTAssertEqual(relaunchedStore.totalStarts, 2, "stats must survive an app relaunch")
    }
}
