import XCTest
@testable import ShouldITextHim

/// Focused tests on the rule layer itself (goal + message + context ->
/// verdict), independent of safety routing or the fallback. The broader,
/// end-to-end product scenarios live in `LocalJudgmentProviderFixtureTests`.
final class DeterministicJudgmentRulesTests: XCTestCase {

    private func quick(
        who: WhoTextedLast = .notSure,
        time: TimeSinceLastMessage = .today,
        responded: DidHeRespond = .noQuestion,
        notes: String = ""
    ) -> ContextSignals {
        ContextSignals(context: .quick(QuickContext(
            whoTextedLast: who, timeSinceLastMessage: time, didHeRespond: responded, additionalNotes: notes
        )))
    }

    func testCanonicalUnansweredClarityQuestionReturnsDontSend() {
        let message = MessageSignals(text: "Hey stranger lol")
        let context = quick(who: .me, time: .oneToThreeDays, responded: .no)
        let result = DeterministicJudgmentRules.evaluate(goal: .getClarity, message: message, context: context)
        XCTAssertEqual(result?.verdict, .dontSend)
    }

    func testSameMessageWithDirectQuestionDoesNotHitTheClarityRule() {
        // A direct follow-up question is not "casual filler," so the
        // unanswered-question rule should not fire for it.
        let message = MessageSignals(text: "Hey, are you still free Saturday?")
        let context = quick(who: .me, time: .oneToThreeDays, responded: .no)
        let result = DeterministicJudgmentRules.evaluate(goal: .getClarity, message: message, context: context)
        XCTAssertNotEqual(result?.verdict, .dontSend)
    }

    func testAngerOverridesCalmBoundaryGoal() {
        let message = MessageSignals(text: "you're pathetic, you always do this")
        let context = quick()
        let result = DeterministicJudgmentRules.evaluate(goal: .setBoundary, message: message, context: context)
        XCTAssertEqual(result?.verdict, .dontSend)
    }

    func testCalmBoundarySettingIsValidatedAsSendable() {
        let message = MessageSignals(text: "I need us to stop texting after midnight, it's not working for me.")
        let context = quick()
        let result = DeterministicJudgmentRules.evaluate(goal: .setBoundary, message: message, context: context)
        XCTAssertEqual(result?.verdict, .send)
    }

    func testRepeatedContactAlwaysWinsRegardlessOfTone() {
        let message = MessageSignals(text: "Just checking if you got my message")
        let context = quick(notes: "This is the third time I've texted since he didn't answer")
        let result = DeterministicJudgmentRules.evaluate(goal: .getClarity, message: message, context: context)
        XCTAssertEqual(result?.verdict, .dontSend)
    }

    func testDoubleTextingRiskSuggestsWaiting() {
        let message = MessageSignals(text: "hey did you see this?")
        let context = quick(who: .me, time: .underAnHour, responded: .noQuestion)
        let result = DeterministicJudgmentRules.evaluate(goal: .checkingIn, message: message, context: context)
        XCTAssertEqual(result?.verdict, .sleep)
    }

    func testLongSilenceWithoutPositiveSignalSuggestsPausing() {
        let message = MessageSignals(text: "Hey, it's been a while")
        let context = quick(who: .me, time: .fourPlusDays, responded: .noQuestion)
        let result = DeterministicJudgmentRules.evaluate(goal: .checkingIn, message: message, context: context)
        XCTAssertEqual(result?.verdict, .sleep)
    }

    func testPositiveReciprocityWithMakePlansSendsConfidently() {
        let message = MessageSignals(text: "Yes! Let's do Saturday, I'm excited")
        let context = quick(who: .him, time: .underAnHour, responded: .yes)
        let result = DeterministicJudgmentRules.evaluate(goal: .makePlans, message: message, context: context)
        XCTAssertEqual(result?.verdict, .send)
    }

    func testAmbiguousReciprocityWhilePushingPlansSuggestsRewrite() {
        let message = MessageSignals(text: "So are we still on for Saturday??")
        let context = quick(who: .him, time: .today, responded: .sortOf)
        let result = DeterministicJudgmentRules.evaluate(goal: .makePlans, message: message, context: context)
        XCTAssertEqual(result?.verdict, .rewrite)
    }

    func testNoRuleMatchesReturnsNilSoCallerCanFallBack() {
        // A goal/context combination none of the obvious rules cover.
        let message = MessageSignals(text: "Hey, random thought, hope you're well")
        let context = quick(who: .notSure, time: .today, responded: .noQuestion)
        let result = DeterministicJudgmentRules.evaluate(goal: .flirt, message: message, context: context)
        XCTAssertNil(result)
    }
}
