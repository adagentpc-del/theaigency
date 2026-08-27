import XCTest
@testable import StartMe

/// Runs every fixture in `StarterFixtures` through the real engine and
/// checks the invariants the product spec requires of *every* starter
/// action, regardless of category: it must exist, it must read as one
/// short instruction (not a plan), and it must be smaller than the task
/// that was typed in.
final class StarterFixtureTests: XCTestCase {
    private var engine: TaskStarterEngine!

    override func setUp() {
        super.setUp()
        engine = TaskStarterEngine()
    }

    func test_atLeastSixtyFixturesExist() {
        XCTAssertGreaterThanOrEqual(StarterFixtures.all.count, 60)
    }

    func test_everyFixture_classifiesAsExpected() {
        for fixture in StarterFixtures.all {
            guard let expected = fixture.expectedCategory else { continue }
            XCTAssertEqual(
                engine.classify(fixture.input),
                expected,
                "\(fixture.input) (\(fixture.note)) expected \(expected)"
            )
        }
    }

    func test_everyFixture_producesANonEmptyAction() {
        for fixture in StarterFixtures.all {
            let action = engine.starterAction(for: fixture.input)
            XCTAssertFalse(
                action.primaryAction.trimmingCharacters(in: .whitespaces).isEmpty,
                "\(fixture.input) (\(fixture.note)) produced an empty action"
            )
        }
    }

    func test_everyFixture_actionIsOneSentence() {
        for fixture in StarterFixtures.all {
            let action = engine.starterAction(for: fixture.input)
            let sentenceEnders = action.primaryAction.filter { $0 == "." || $0 == "!" || $0 == "?" }
            XCTAssertLessThanOrEqual(
                sentenceEnders.count,
                1,
                "\(fixture.input) (\(fixture.note)) produced more than one sentence: \(action.primaryAction)"
            )
        }
    }

    /// The critical invariant from docs/PRODUCT_SPEC.md: the returned
    /// action must be smaller than the requested task — never a full plan.
    /// Checked as: short word count, and no multi-step language.
    func test_everyFixture_actionIsSmallerThanTheTask() {
        let planningWords = ["step 1", "step one", "first,", "then,", "finally,", "plan:", "schedule"]
        for fixture in StarterFixtures.all {
            let action = engine.starterAction(for: fixture.input)
            let wordCount = action.primaryAction.split(separator: " ").count
            XCTAssertLessThanOrEqual(
                wordCount,
                12,
                "\(fixture.input) (\(fixture.note)) produced a \(wordCount)-word action: \(action.primaryAction)"
            )
            let lowered = action.primaryAction.lowercased()
            for word in planningWords {
                XCTAssertFalse(
                    lowered.contains(word),
                    "\(fixture.input) (\(fixture.note)) reads like a plan, not a tiny step: \(action.primaryAction)"
                )
            }
        }
    }

    func test_everyFixture_categoryMatchesActionCategory() {
        for fixture in StarterFixtures.all {
            let action = engine.starterAction(for: fixture.input)
            XCTAssertEqual(action.category, engine.classify(fixture.input))
        }
    }
}
