import XCTest
@testable import Evidence

final class EvidenceTests: XCTestCase {
    func testEvidenceRoundTripsCodable() throws {
        let item = EVItem(text: "Closed the deal", kind: "Win", source: "Client")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(EVItem.self, from: data)
        XCTAssertEqual(decoded.text, item.text)
        XCTAssertEqual(decoded.kind, "Win")
    }

    @MainActor
    func testDeleteRemovesEvidenceFromVault() {
        let store = EVStore()
        store.items = []
        let item = EVItem(text: "A real receipt", kind: "Win")
        store.add(item)
        XCTAssertEqual(store.items.count, 1)
        store.delete(item.id)
        XCTAssertTrue(store.items.isEmpty)
    }

    @MainActor
    func testFavoriteReceiptsArePrioritized() {
        let store = EVStore()
        store.items = []
        let normal = EVItem(text: "Normal", kind: "Win")
        var favorite = EVItem(text: "Favorite", kind: "Compliment")
        favorite.favorite = true
        store.items = [normal, favorite]
        XCTAssertEqual(store.nextReceipt()?.id, favorite.id)
    }
}
