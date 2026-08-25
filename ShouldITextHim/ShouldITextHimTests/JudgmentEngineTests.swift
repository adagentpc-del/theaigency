import XCTest
@testable import ShouldITextHim

final class JudgmentEngineTests: XCTestCase {

    func testNormalFriendlyMessageSendsIt() {
        let result = JudgmentEngine.judge("Hey! Had so much fun last night, thank you for dinner.")
        XCTAssertEqual(result.verdict, .send)
        XCTAssertFalse(result.isSafetyRouted)
        XCTAssertTrue(result.riskFlags.isEmpty)
    }

    func testAngryMessageDoesNotSend() {
        let result = JudgmentEngine.judge("You always do this, you're so pathetic, I hate you!!!")
        XCTAssertEqual(result.verdict, .dontSend)
        XCTAssertFalse(result.isSafetyRouted)
    }

    func testAnxiousDoubleTextingSuggestsRewrite() {
        let result = JudgmentEngine.judge("hello??? are you ignoring me? please respond please answer, did you see my last text???")
        XCTAssertEqual(result.verdict, .rewrite)
    }

    func testBreakupLanguageSuggestsSleepOnIt() {
        let result = JudgmentEngine.judge("I think we should break up, this isn't working anymore.")
        XCTAssertEqual(result.verdict, .sleep)
    }

    func testVeryLongMessageSuggestsRewrite() {
        let longText = Array(repeating: "word", count: 150).joined(separator: " ")
        let result = JudgmentEngine.judge(longText)
        XCTAssertEqual(result.verdict, .rewrite)
    }

    func testMultilineInputIsHandled() {
        let text = "Hey,\n\nJust wanted to say\nthanks for today.\n\nTalk soon."
        let result = JudgmentEngine.judge(text)
        XCTAssertNotNil(result.reason)
        XCTAssertFalse(result.reason.isEmpty)
    }

    func testEmptyInputDoesNotCrashAndReturnsAResult() {
        let result = JudgmentEngine.judge("")
        XCTAssertFalse(result.reason.isEmpty)
    }

    func testWhitespaceOnlyInputDoesNotCrash() {
        let result = JudgmentEngine.judge("   \n\t  ")
        XCTAssertFalse(result.reason.isEmpty)
    }

    // MARK: - Safety routing

    func testViolenceThreatIsSafetyRouted() {
        let result = JudgmentEngine.judge("If you don't answer me I'll hurt you.")
        XCTAssertTrue(result.isSafetyRouted)
        XCTAssertEqual(result.verdict, .dontSend)
        XCTAssertTrue(result.riskFlags.contains(.violenceThreat) || result.riskFlags.contains(.coercion))
    }

    func testSelfHarmStatementIsSafetyRouted() {
        let result = JudgmentEngine.judge("Honestly if they don't reply I want to kill myself.")
        XCTAssertTrue(result.isSafetyRouted)
        XCTAssertTrue(result.riskFlags.contains(.selfHarm))
    }

    func testStalkingLanguageIsSafetyRouted() {
        let result = JudgmentEngine.judge("I know where you live and I'll be outside your house tonight.")
        XCTAssertTrue(result.isSafetyRouted)
        XCTAssertTrue(result.riskFlags.contains(.stalking))
    }

    func testSafetyRoutedResponseNeverContainsAJoke() {
        let result = JudgmentEngine.judge("I'll kill you if you don't text me back right now.")
        XCTAssertTrue(result.isSafetyRouted)
        // A calm, non-comedic reason should never end in an exclamation-heavy
        // or playful tone; this is a coarse guard against regressions that
        // accidentally route risky text through the witty copy paths.
        XCTAssertFalse(result.reason.contains("😂"))
    }
}
