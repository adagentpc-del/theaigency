import XCTest
@testable import ShouldITextHim

final class RewriteEngineTests: XCTestCase {

    func testEveryIntentReturnsUpToThreeNonEmptyOptions() {
        for intent in Intent.allCases {
            let options = RewriteEngine.options(for: intent)
            XCTAssertFalse(options.isEmpty, "\(intent) should return at least one option")
            XCTAssertLessThanOrEqual(options.count, 3, "\(intent) should return at most 3 options")
            for option in options {
                XCTAssertFalse(option.text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    func testOptionsAreDistinctPerIntent() {
        let flirt = Set(RewriteEngine.options(for: .flirt).map(\.text))
        let apology = Set(RewriteEngine.options(for: .apologize).map(\.text))
        XCTAssertTrue(flirt.isDisjoint(with: apology))
    }
}
