import XCTest
@testable import ShouldITextHim

final class FakeClipboard: ClipboardWriting {
    private(set) var lastWrite: String?
    func write(_ text: String) { lastWrite = text }
}

@MainActor
final class JudgeViewModelTests: XCTestCase {

    private func makeViewModel(clipboard: FakeClipboard = FakeClipboard()) -> JudgeViewModel {
        JudgeViewModel(clipboard: clipboard, judgingDelayNanoseconds: 0)
    }

    func testBlankInputIsInvalid() {
        let vm = makeViewModel()
        vm.inputText = ""
        XCTAssertFalse(vm.isInputValid)
    }

    func testWhitespaceOnlyInputIsInvalid() {
        let vm = makeViewModel()
        vm.inputText = "   \n\t "
        XCTAssertFalse(vm.isInputValid)
    }

    func testNormalInputIsValid() {
        let vm = makeViewModel()
        vm.inputText = "Hey, are we still on for tonight?"
        XCTAssertTrue(vm.isInputValid)
    }

    func testJudgeDoesNothingForBlankInput() async {
        let vm = makeViewModel()
        vm.inputText = ""
        await vm.judge()
        XCTAssertEqual(vm.phase, .input)
    }

    func testJudgeTransitionsToVerdict() async {
        let vm = makeViewModel()
        vm.inputText = "Hey! Thanks again for today, that was fun."
        await vm.judge()
        guard case .verdict = vm.phase else {
            return XCTFail("Expected verdict phase, got \(vm.phase)")
        }
    }

    func testResetReturnsToInputAndClearsText() async {
        let vm = makeViewModel()
        vm.inputText = "Some message"
        await vm.judge()
        vm.reset()
        XCTAssertEqual(vm.phase, .input)
        XCTAssertEqual(vm.inputText, "")
    }

    func testStartRewriteOnlyWorksFromVerdict() {
        let vm = makeViewModel()
        vm.startRewrite()
        XCTAssertEqual(vm.phase, .input)
    }

    func testFullRewriteFlow() async {
        let vm = makeViewModel()
        vm.inputText = "Hey! Thanks again for today, that was fun."
        await vm.judge()
        vm.startRewrite()
        XCTAssertEqual(vm.phase, .rewriteIntent)

        vm.selectIntent(.getClarity)
        guard case .rewriteResult(let intent, let options) = vm.phase else {
            return XCTFail("Expected rewriteResult phase")
        }
        XCTAssertEqual(intent, .getClarity)
        XCTAssertFalse(options.isEmpty)
    }

    func testCopyWritesToClipboardAndSetsConfirmation() {
        let clipboard = FakeClipboard()
        let vm = makeViewModel(clipboard: clipboard)
        vm.copy("test message")
        XCTAssertEqual(clipboard.lastWrite, "test message")
        XCTAssertTrue(vm.lastCopiedConfirmation)
    }

    func testRelaunchEquivalentStartsFreshWithNoRetainedText() {
        // Simulates "relaunch" by constructing a brand new view model, the
        // same as a fresh process start would, since no state is persisted.
        let vm = makeViewModel()
        XCTAssertEqual(vm.phase, .input)
        XCTAssertEqual(vm.inputText, "")
    }
}
