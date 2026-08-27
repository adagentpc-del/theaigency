import Foundation
@testable import StartMe

final class FakeDateProvider: CurrentDateProviding {
    var currentDate: Date

    init(_ date: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.currentDate = date
    }

    func now() -> Date { currentDate }

    func advance(by seconds: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(seconds)
    }
}
