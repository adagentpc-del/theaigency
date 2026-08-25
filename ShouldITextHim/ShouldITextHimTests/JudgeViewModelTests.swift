import XCTest
@testable import ShouldITextHim

final class FakeClipboard: ClipboardWriting {
    private(set) var lastWrite: String?
    func write(_ text: String) { lastWrite = text }
}

/// Stubs judgment entirely so these tests exercise only the view model's
/// step-navigation and state-management logic. The real deterministic
/// engine is exercised separately and thoroughly by
/// `LocalJudgmentProviderFixtureTests`.
struct FakeJudgmentProvider: JudgmentProvider {
    let result: JudgmentResult
    func judge(_ request: JudgmentRequest) async -> JudgmentResult { result }
}

private let stubResult = JudgmentResult(
    verdict: .send,
    reason: "stub",
    riskFlags: [],
    isSafetyRouted: false
)

@MainActor
final class JudgeViewModelTests: XCTestCase {

    private func makeViewModel(
        result: JudgmentResult = stubResult,
        clipboard: FakeClipboard = FakeClipboard()
    ) -> JudgeViewModel {
        JudgeViewModel(
            provider: FakeJudgmentProvider(result: result),
            clipboard: clipboard,
            judgingDelayNanoseconds: 0
        )
    }

    // MARK: - Step 1: message

    func testBlankMessageIsInvalid() {
        let vm = makeViewModel()
        vm.proposedMessage = ""
        XCTAssertFalse(vm.isMessageValid)
    }

    func testWhitespaceOnlyMessageIsInvalid() {
        let vm = makeViewModel()
        vm.proposedMessage = "   \n\t "
        XCTAssertFalse(vm.isMessageValid)
    }

    func testProceedToGoalDoesNothingWithBlankMessage() {
        let vm = makeViewModel()
        vm.proposedMessage = ""
        vm.proceedToGoal()
        XCTAssertEqual(vm.phase, .message)
    }

    func testProceedToGoalAdvancesWithValidMessage() {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey, are we still on for tonight?"
        vm.proceedToGoal()
        XCTAssertEqual(vm.phase, .goal)
    }

    // MARK: - Step 2: goal

    func testSelectGoalAdvancesToContext() {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.proceedToGoal()
        vm.selectGoal(.getClarity)
        XCTAssertEqual(vm.phase, .context)
        XCTAssertEqual(vm.selectedGoal, .getClarity)
    }

    // MARK: - Back navigation

    func testBackToMessageFromGoal() {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.proceedToGoal()
        vm.backToMessage()
        XCTAssertEqual(vm.phase, .message)
    }

    func testBackToGoalFromContext() {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.proceedToGoal()
        vm.selectGoal(.flirt)
        vm.backToGoal()
        XCTAssertEqual(vm.phase, .goal)
    }

    // MARK: - Step 3: context validation

    func testQuickContextInvalidUntilAllThreeAnswered() {
        let vm = makeViewModel()
        vm.contextMethod = .quick
        XCTAssertFalse(vm.isContextValid)
        vm.quickWhoTextedLast = .me
        XCTAssertFalse(vm.isContextValid)
        vm.quickTimeSinceLastMessage = .today
        XCTAssertFalse(vm.isContextValid)
        vm.quickDidHeRespond = .no
        XCTAssertTrue(vm.isContextValid)
    }

    func testConversationContextRequiresNonBlankText() {
        let vm = makeViewModel()
        vm.contextMethod = .conversation
        XCTAssertFalse(vm.isContextValid)
        vm.conversationText = "   "
        XCTAssertFalse(vm.isContextValid)
        vm.conversationText = "Him: hey\nMe: hey!"
        XCTAssertTrue(vm.isContextValid)
    }

    // MARK: - Step 4: judgment only fires after all three steps

    func testSubmitContextDoesNothingWithoutGoal() async {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.contextMethod = .quick
        vm.quickWhoTextedLast = .me
        vm.quickTimeSinceLastMessage = .today
        vm.quickDidHeRespond = .noQuestion
        await vm.submitContext()
        XCTAssertEqual(vm.phase, .message)
    }

    func testSubmitContextDoesNothingWithoutContext() async {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.proceedToGoal()
        vm.selectGoal(.checkingIn)
        await vm.submitContext()
        XCTAssertEqual(vm.phase, .context)
    }

    func testSubmitContextProducesVerdictOnlyAfterAllThreeSteps() async {
        let vm = makeViewModel()
        XCTAssertEqual(vm.phase, .message)

        vm.proposedMessage = "Hey, how's it going?"
        vm.proceedToGoal()
        XCTAssertEqual(vm.phase, .goal)

        vm.selectGoal(.checkingIn)
        XCTAssertEqual(vm.phase, .context)

        vm.contextMethod = .quick
        vm.quickWhoTextedLast = .him
        vm.quickTimeSinceLastMessage = .today
        vm.quickDidHeRespond = .yes

        await vm.submitContext()
        guard case .verdict(let request, let result) = vm.phase else {
            return XCTFail("Expected verdict phase, got \(vm.phase)")
        }
        XCTAssertEqual(request.proposedMessage, "Hey, how's it going?")
        XCTAssertEqual(request.goal, .checkingIn)
        XCTAssertEqual(result, stubResult)
    }

    // MARK: - Rewrite

    func testStartRewriteUsesGoalFromTheOriginalRequest() async {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.proceedToGoal()
        vm.selectGoal(.apologize)
        vm.contextMethod = .quick
        vm.quickWhoTextedLast = .me
        vm.quickTimeSinceLastMessage = .today
        vm.quickDidHeRespond = .noQuestion
        await vm.submitContext()

        vm.startRewrite()
        guard case .rewriteResult(let goal, let options) = vm.phase else {
            return XCTFail("Expected rewriteResult phase")
        }
        XCTAssertEqual(goal, .apologize)
        XCTAssertFalse(options.isEmpty)
    }

    func testStartRewriteOnlyWorksFromVerdict() {
        let vm = makeViewModel()
        vm.startRewrite()
        XCTAssertEqual(vm.phase, .message)
    }

    // MARK: - Reset / relaunch

    func testResetClearsEveryStepsState() async {
        let vm = makeViewModel()
        vm.proposedMessage = "Hey"
        vm.proceedToGoal()
        vm.selectGoal(.getClosure)
        vm.contextMethod = .conversation
        vm.conversationText = "Him: hey\nMe: hey"
        vm.quickAdditionalNotes = "note"

        vm.reset()

        XCTAssertEqual(vm.phase, .message)
        XCTAssertEqual(vm.proposedMessage, "")
        XCTAssertNil(vm.selectedGoal)
        XCTAssertEqual(vm.contextMethod, .quick)
        XCTAssertEqual(vm.conversationText, "")
        XCTAssertNil(vm.quickWhoTextedLast)
        XCTAssertNil(vm.quickTimeSinceLastMessage)
        XCTAssertNil(vm.quickDidHeRespond)
        XCTAssertEqual(vm.quickAdditionalNotes, "")
    }

    func testRelaunchEquivalentStartsFreshWithNoRetainedState() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.phase, .message)
        XCTAssertEqual(vm.proposedMessage, "")
        XCTAssertNil(vm.selectedGoal)
    }

    // MARK: - Copy

    func testCopyWritesToClipboardAndSetsConfirmation() {
        let clipboard = FakeClipboard()
        let vm = makeViewModel(clipboard: clipboard)
        vm.copy("test message")
        XCTAssertEqual(clipboard.lastWrite, "test message")
        XCTAssertTrue(vm.lastCopiedConfirmation)
    }
}
