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
}
