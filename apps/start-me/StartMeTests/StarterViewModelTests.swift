import XCTest
@testable import StartMe

@MainActor
final class StarterViewModelTests: XCTestCase {
    func test_initialState_showsPrimaryAction() {
        let viewModel = StarterViewModel(originalInput: "go to the gym", engine: TaskStarterEngine())
        XCTAssertEqual(viewModel.displayedActionText, "Put your shoes on.")
    }

    func test_makeSmaller_walksThroughReductionLevels() {
        let viewModel = StarterViewModel(originalInput: "go to the gym", engine: TaskStarterEngine())
        let primary = viewModel.displayedActionText

        viewModel.makeSmaller()
        let firstReduction = viewModel.displayedActionText
        XCTAssertNotEqual(firstReduction, primary)

        viewModel.makeSmaller()
        let secondReduction = viewModel.displayedActionText
        XCTAssertNotEqual(secondReduction, firstReduction)
    }

    func test_makeSmaller_neverGoesPastAvailableReductionsOrCrashes() {
        let viewModel = StarterViewModel(originalInput: "go to the gym", engine: TaskStarterEngine())
        for _ in 0..<10 {
            viewModel.makeSmaller()
        }
        XCTAssertFalse(viewModel.canMakeSmaller)
        XCTAssertFalse(viewModel.displayedActionText.isEmpty)
    }

    func test_differentStart_changesActionAndResetsReductionLevel() {
        let viewModel = StarterViewModel(originalInput: "go to the gym", engine: TaskStarterEngine())
        viewModel.makeSmaller()
        XCTAssertTrue(viewModel.reductionLevel > 0)

        viewModel.requestDifferentStart()
        XCTAssertEqual(viewModel.reductionLevel, 0)
    }

    func test_differentStart_staysWithinSameCategory() {
        let viewModel = StarterViewModel(originalInput: "go to the gym", engine: TaskStarterEngine())
        viewModel.requestDifferentStart()
        XCTAssertEqual(viewModel.action.category, .workout)
    }
}
