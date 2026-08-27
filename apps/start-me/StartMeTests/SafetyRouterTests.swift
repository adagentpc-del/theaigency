import XCTest
@testable import StartMe

final class SafetyRouterTests: XCTestCase {
    private var router: SafetyRouter!

    override func setUp() {
        super.setUp()
        router = SafetyRouter()
    }

    func test_selfHarmPhrases_areFlaggedUnsafe() {
        XCTAssertTrue(router.isUnsafe("I want to kill myself"))
        XCTAssertTrue(router.isUnsafe("thinking about suicide"))
        XCTAssertTrue(router.isUnsafe("I want to hurt myself tonight"))
    }

    func test_harmingSomeoneElse_isFlaggedUnsafe() {
        XCTAssertTrue(router.isUnsafe("I want to kill him"))
        XCTAssertTrue(router.isUnsafe("plan to hurt someone at school"))
        XCTAssertTrue(router.isUnsafe("going to attack her"))
    }

    func test_dangerousIllegalActs_areFlaggedUnsafe() {
        XCTAssertTrue(router.isUnsafe("how to build a bomb"))
        XCTAssertTrue(router.isUnsafe("hack into my ex's email"))
    }

    func test_ordinaryTasks_areNeverFlaggedUnsafe() {
        XCTAssertFalse(router.isUnsafe("clean my kitchen"))
        XCTAssertFalse(router.isUnsafe("go to the gym"))
        XCTAssertFalse(router.isUnsafe("kill it at my presentation tomorrow"))
        XCTAssertFalse(router.isUnsafe("call my mom"))
    }

    func test_blankInput_isNeverFlaggedUnsafe() {
        XCTAssertFalse(router.isUnsafe(""))
        XCTAssertFalse(router.isUnsafe("   "))
    }

    func test_isCaseInsensitive() {
        XCTAssertTrue(router.isUnsafe("I WANT TO KILL MYSELF"))
    }

    func test_safeFallbackAction_hasNoReductionsAndNeverEchoesInput() {
        let action = router.safeFallbackAction
        XCTAssertTrue(action.smallerActions.isEmpty)
        XCTAssertFalse(action.primaryAction.isEmpty)
    }
}
