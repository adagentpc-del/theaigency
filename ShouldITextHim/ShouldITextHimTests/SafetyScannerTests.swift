import XCTest
@testable import ShouldITextHim

final class SafetyScannerTests: XCTestCase {

    func testCleanTextHasNoFlags() {
        XCTAssertTrue(SafetyScanner.scan("Hey, are we still on for coffee Friday?").isEmpty)
    }

    func testViolenceThreatIsFlagged() {
        XCTAssertTrue(SafetyScanner.scan("I will kill you if you do that again.").contains(.violenceThreat))
    }

    func testSelfHarmIsFlagged() {
        XCTAssertTrue(SafetyScanner.scan("I just want to end my life.").contains(.selfHarm))
    }

    func testCoercionIsFlagged() {
        XCTAssertTrue(SafetyScanner.scan("Send it or I'll make sure everyone knows.").contains(.coercion))
    }

    func testStalkingIsFlagged() {
        XCTAssertTrue(SafetyScanner.scan("I followed you home yesterday, I know your schedule now.").contains(.stalking))
    }

    func testSexualExploitationIsFlagged() {
        XCTAssertTrue(SafetyScanner.scan("Send nudes or I'll post your pictures everywhere.").contains(.sexualExploitation))
    }

    func testAbuseIndicatorIsFlagged() {
        XCTAssertTrue(SafetyScanner.scan("You're nothing without me and you never will be.").contains(.abuseIndicator))
    }

    func testCaseInsensitiveMatching() {
        XCTAssertTrue(SafetyScanner.scan("I WILL KILL YOU").contains(.violenceThreat))
    }

    func testSafeResponseNeverEmpty() {
        let response = SafetyScanner.safeResponse(for: [.violenceThreat])
        XCTAssertFalse(response.reason.isEmpty)
        XCTAssertEqual(response.verdict, .dontSend)
        XCTAssertTrue(response.isSafetyRouted)
    }
}
