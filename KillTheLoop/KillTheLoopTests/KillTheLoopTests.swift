import XCTest
@testable import KillTheLoop

final class KillTheLoopTests: XCTestCase {
    @MainActor
    func testResolveMovesLoopToClosed() {
        let store = KLStore()
        store.active = []
        store.closed = []
        store.add("Call dentist")
        XCTAssertEqual(store.active.count, 1)
        _ = store.resolveCurrent(status: "done")
        XCTAssertEqual(store.active.count, 0)
        XCTAssertEqual(store.closed.first?.status, "done")
    }

    func testLoopRoundTripsCodable() throws {
        let item = KLItem(text: "Return package")
        let data = try JSONEncoder().encode(item)
        XCTAssertEqual(try JSONDecoder().decode(KLItem.self, from: data).text, "Return package")
    }
}
