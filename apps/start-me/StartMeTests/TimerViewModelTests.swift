import XCTest
@testable import StartMe

@MainActor
final class TimerViewModelTests: XCTestCase {
    func test_initialState_showsFullDuration() {
        let viewModel = TimerViewModel(session: .initial(), dateProvider: FakeDateProvider())
        XCTAssertEqual(viewModel.remainingSeconds, 60)
        XCTAssertEqual(viewModel.formattedTime, "1:00")
        XCTAssertFalse(viewModel.isComplete)
    }

    func test_continuationSession_showsFiveMinutes() {
        let viewModel = TimerViewModel(session: .continuation(), dateProvider: FakeDateProvider())
        XCTAssertEqual(viewModel.remainingSeconds, 300)
        XCTAssertEqual(viewModel.formattedTime, "5:00")
    }

    func test_elapsedTimeCalculation_isAccurateRegardlessOfTicks() {
        let dateProvider = FakeDateProvider()
        let viewModel = TimerViewModel(session: .initial(), dateProvider: dateProvider)
        viewModel.start()

        dateProvider.advance(by: 45)
        viewModel.refreshFromWallClock()

        XCTAssertEqual(viewModel.remainingSeconds, 15)
        XCTAssertEqual(viewModel.formattedTime, "0:15")
        XCTAssertFalse(viewModel.isComplete)
    }

    func test_completion_firesOnCompleteAndSetsIsComplete() {
        let dateProvider = FakeDateProvider()
        let viewModel = TimerViewModel(session: .initial(), dateProvider: dateProvider)
        var didComplete = false
        viewModel.onComplete = { didComplete = true }
        viewModel.start()

        dateProvider.advance(by: 60)
        viewModel.refreshFromWallClock()

        XCTAssertTrue(viewModel.isComplete)
        XCTAssertEqual(viewModel.remainingSeconds, 0)
        XCTAssertTrue(didComplete)
    }

    func test_overshootingElapsedTime_neverGoesNegative() {
        let dateProvider = FakeDateProvider()
        let viewModel = TimerViewModel(session: .initial(), dateProvider: dateProvider)
        viewModel.start()

        // Simulates a long background interruption past the timer's duration.
        dateProvider.advance(by: 500)
        viewModel.refreshFromWallClock()

        XCTAssertEqual(viewModel.remainingSeconds, 0)
        XCTAssertTrue(viewModel.isComplete)
    }

    func test_onComplete_firesOnlyOnce() {
        let dateProvider = FakeDateProvider()
        let viewModel = TimerViewModel(session: .initial(), dateProvider: dateProvider)
        var completionCount = 0
        viewModel.onComplete = { completionCount += 1 }
        viewModel.start()

        dateProvider.advance(by: 60)
        viewModel.refreshFromWallClock()
        viewModel.refreshFromWallClock()
        viewModel.refreshFromWallClock()

        XCTAssertEqual(completionCount, 1)
    }
}
