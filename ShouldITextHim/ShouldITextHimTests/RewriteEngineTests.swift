import XCTest
@testable import ShouldITextHim

final class RewriteEngineTests: XCTestCase {

    func testEveryGoalReturnsUpToThreeNonEmptyOptions() {
        for goal in Goal.allCases {
            let options = RewriteEngine.options(for: goal)
            XCTAssertFalse(options.isEmpty, "\(goal) should return at least one option")
            XCTAssertLessThanOrEqual(options.count, 3, "\(goal) should return at most 3 options")
            for option in options {
                XCTAssertFalse(option.text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    func testOptionsAreDistinctPerGoal() {
        let flirt = Set(RewriteEngine.options(for: .flirt).map(\.text))
        let apology = Set(RewriteEngine.options(for: .apologize).map(\.text))
        XCTAssertTrue(flirt.isDisjoint(with: apology))
    }

    func testCheckingInGoalHasOptions() {
        XCTAssertFalse(RewriteEngine.options(for: .checkingIn).isEmpty)
    }
}
