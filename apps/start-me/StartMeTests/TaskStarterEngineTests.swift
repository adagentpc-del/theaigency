import XCTest
@testable import StartMe

final class TaskStarterEngineTests: XCTestCase {
    private var engine: TaskStarterEngine!

    override func setUp() {
        super.setUp()
        engine = TaskStarterEngine()
    }

    // MARK: - Spec-exact examples (docs/PRODUCT_SPEC.md section 10)

    func test_cleanApartment_producesSpecExactAction() {
        let action = engine.starterAction(for: "clean my entire apartment")
        XCTAssertEqual(action.primaryAction, "Throw away one piece of trash.")
        XCTAssertEqual(action.category, .cleaning)
    }

    func test_goToTheGym_producesSpecExactAction() {
        let action = engine.starterAction(for: "go to the gym")
        XCTAssertEqual(action.primaryAction, "Put your shoes on.")
        XCTAssertEqual(action.category, .workout)
    }

    func test_answerEmails_producesSpecExactAction() {
        let action = engine.starterAction(for: "answer my emails")
        XCTAssertEqual(action.primaryAction, "Open your inbox.")
        XCTAssertEqual(action.category, .email)
    }

    func test_fileMyTaxes_producesSpecExactAction() {
        let action = engine.starterAction(for: "file my taxes")
        XCTAssertEqual(action.primaryAction, "Open the website or folder you use for your taxes.")
        XCTAssertEqual(action.category, .taxes)
    }

    func test_unknownInputWithNounPhrase_producesDynamicFallback() {
        let action = engine.starterAction(for: "finish the Johnson thing")
        XCTAssertEqual(action.primaryAction, "Open whatever you need to work on the Johnson thing.")
        XCTAssertEqual(action.reassurance, "Don't finish it. Just open it.")
        XCTAssertEqual(action.category, .general)
    }

    // MARK: - Blank / whitespace input

    func test_blankInput_doesNotCrashAndReturnsGeneralAction() {
        let action = engine.starterAction(for: "")
        XCTAssertFalse(action.primaryAction.isEmpty)
        XCTAssertEqual(action.category, .general)
    }

    func test_whitespaceOnlyInput_doesNotCrashAndReturnsGeneralAction() {
        let action = engine.starterAction(for: "   \n\t  ")
        XCTAssertFalse(action.primaryAction.isEmpty)
        XCTAssertEqual(action.category, .general)
    }

    // MARK: - Classification

    func test_classify_isCaseInsensitive() {
        XCTAssertEqual(engine.classify("GO TO THE GYM"), .workout)
        XCTAssertEqual(engine.classify("Go To The Gym"), .workout)
    }

    func test_classify_unknownInputFallsBackToGeneral() {
        XCTAssertEqual(engine.classify("asdkjfh qqzz nonsense"), .general)
    }

    // MARK: - Alternate action ("Give me a different start")

    func test_alternateAction_differsFromCurrentWhenPossible() {
        let first = engine.starterAction(for: "go to the gym")
        let alternate = engine.alternateAction(current: first, originalInput: "go to the gym")
        XCTAssertNotEqual(alternate.primaryAction, first.primaryAction)
        XCTAssertEqual(alternate.category, first.category)
    }

    func test_alternateAction_neverCrashesForSingleEntryCategoryAndReturnsSomething() {
        // Even if a category only had one variant, alternateAction must
        // still return a valid, non-empty action rather than crashing.
        let action = StarterAction(primaryAction: "Only one.", reassurance: nil, smallerActions: [], category: .general)
        let alternate = engine.alternateAction(current: action, originalInput: "get my shit together")
        XCTAssertFalse(alternate.primaryAction.isEmpty)
    }

    // MARK: - Safety routing

    func test_unsafeInput_neverProducesActionableStarterStep() {
        let action = engine.starterAction(for: "I want to hurt myself")
        XCTAssertTrue(action.smallerActions.isEmpty)
        XCTAssertEqual(action.primaryAction, SafetyRouter().safeFallbackAction.primaryAction)
    }

    func test_unsafeInput_alternateActionAlsoRoutesToSafety() {
        let unsafeInput = "I want to kill him"
        let initial = engine.starterAction(for: unsafeInput)
        let alternate = engine.alternateAction(current: initial, originalInput: unsafeInput)
        XCTAssertEqual(alternate.primaryAction, SafetyRouter().safeFallbackAction.primaryAction)
    }

    // MARK: - Long / special-character / Unicode input

    func test_longInput_doesNotCrashAndProducesSmallAction() {
        let longInput = String(repeating: "clean the apartment and also do everything else ", count: 20)
        let action = engine.starterAction(for: longInput)
        XCTAssertFalse(action.primaryAction.isEmpty)
        XCTAssertLessThan(action.primaryAction.count, longInput.count)
    }

    func test_unicodeInput_doesNotCrash() {
        let action = engine.starterAction(for: "打扫厨房 🧹✨ タスク")
        XCTAssertFalse(action.primaryAction.isEmpty)
    }

    func test_specialCharacterInput_doesNotCrash() {
        let action = engine.starterAction(for: "clean the kitchen!!! @@@ ### $$$ 🔥🔥🔥")
        XCTAssertEqual(action.category, .cleaning)
    }
}
