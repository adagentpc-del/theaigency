import XCTest
@testable import StartMe

final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_defaultsToHapticsEnabled() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.hapticsEnabled)
    }

    func test_hapticsPreference_persistsAcrossInstances() {
        let store = SettingsStore(defaults: defaults)
        store.hapticsEnabled = false

        let relaunchedStore = SettingsStore(defaults: defaults)
        XCTAssertFalse(relaunchedStore.hapticsEnabled, "the haptics preference must survive an app relaunch")
    }
}
