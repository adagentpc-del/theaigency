import XCTest
@testable import KeepOne

final class KeepOneTests: XCTestCase {
    func testPairingEngineProducesUniqueValidPairs() {
        let items = (1...8).map { KOContender(name: "Item \($0)") }
        let pairs = KOPairingEngine.makePairs(for: items)
        XCTAssertFalse(pairs.isEmpty)
        XCTAssertLessThanOrEqual(pairs.count, 24)
        XCTAssertTrue(pairs.allSatisfy { $0.count == 2 && $0[0] != $0[1] })
    }

    func testRankingPrefersHigherScore() {
        var a = KOContender(name: "A"); a.wins = 3; a.losses = 0
        var b = KOContender(name: "B"); b.wins = 1; b.losses = 2
        XCTAssertEqual(KOPairingEngine.ranked([b,a]).first?.name, "A")
    }
}
