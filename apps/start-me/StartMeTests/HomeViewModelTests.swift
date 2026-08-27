import XCTest
@testable import StartMe

@MainActor
final class HomeViewModelTests: XCTestCase {
    private func makeViewModel() -> HomeViewModel {
        let suiteName = "HomeViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return HomeViewModel(statsStore: StatsStore(defaults: defaults))
    }

    func test_blankInput_disablesStart() {
        let viewModel = makeViewModel()
        viewModel.taskText = ""
        XCTAssertFalse(viewModel.canStart)
    }

    func test_whitespaceOnlyInput_disablesStart() {
        let viewModel = makeViewModel()
        viewModel.taskText = "   \n  "
        XCTAssertFalse(viewModel.canStart)
    }

    func test_realInput_enablesStart() {
        let viewModel = makeViewModel()
        viewModel.taskText = "clean my kitchen"
        XCTAssertTrue(viewModel.canStart)
    }

    func test_statsSummary_withNoHistory_isNoShameComeback() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.statsSummaryText, "You came back. That counts.")
    }

    func test_currentPlaceholder_isAlwaysAValidExample() {
        let viewModel = makeViewModel()
        XCTAssertTrue(HomeViewModel.rotatingExamples.contains(viewModel.currentPlaceholder))
    }
}
