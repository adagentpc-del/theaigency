import XCTest
@testable import KeepOne

final class KeepOneTests: XCTestCase {
    func testPairingEngineProducesUniqueValidPairs() {
        let items = (1...8).map { KOContender(name: "Item \($0)") }
        let pairs = KOPairingEngine.makePairs(for: items)
        XCTAssertFalse(pairs.isEmpty)
        XCTAssertLessThanOrEqual(pairs.count, 24)
        XCTAssertTrue(pairs.allSatisfy { $0.count == 2 && $0[0] != $0[1] })
        let keys = pairs.map { $0.map(\.uuidString).sorted().joined(separator: "|") }
        XCTAssertEqual(Set(keys).count, keys.count)
    }

    func testRankingPrefersHigherScore() {
        var a = KOContender(name: "A"); a.wins = 3; a.losses = 0
        var b = KOContender(name: "B"); b.wins = 1; b.losses = 2
        XCTAssertEqual(KOPairingEngine.ranked([b, a]).first?.name, "A")
    }

    @MainActor
    func testUndoRestoresExactDecisionStats() {
        let store = KOStore()
        store.current = nil
        store.history = []
        let items = [KOContender(name: "A"), KOContender(name: "B"), KOContender(name: "C")]
        store.start(category: "Test", contenders: items)
        guard let pair = store.current?.pairings.first, let winner = pair.first else {
            XCTFail("Expected a pairing")
            return
        }
        store.choose(winner)
        XCTAssertEqual(store.current?.currentPairIndex, 1)
        XCTAssertEqual(store.current?.decisions.count, 1)
        store.undo()
        XCTAssertEqual(store.current?.currentPairIndex, 0)
        XCTAssertEqual(store.current?.decisions.count, 0)
        XCTAssertTrue(store.current?.contenders.allSatisfy { $0.wins == 0 && $0.losses == 0 } == true)
        store.clearCurrent()
    }
}
