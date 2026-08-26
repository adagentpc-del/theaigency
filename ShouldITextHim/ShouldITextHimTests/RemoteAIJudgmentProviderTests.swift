import XCTest
@testable import ShouldITextHim

/// Tests `RemoteAIJudgmentProvider`'s plumbing — local pre-filters,
/// request/response handling, strict validation, and graceful fallback —
/// using `MockURLProtocol` so no real network call or API key is ever
/// involved. This is NOT a test of the AI's judgment quality (that
/// requires a real deployed endpoint — see `RemoteAIJudgmentProviderLiveTests`);
/// it proves the client correctly surfaces whatever the server returns,
/// and never fakes confidence when the server can't be reached.
@MainActor
final class RemoteAIJudgmentProviderTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    private func makeProvider() -> RemoteAIJudgmentProvider {
        RemoteAIJudgmentProvider(
            endpoint: URL(string: "https://test.invalid/api/judge")!,
            urlSession: MockURLProtocol.makeSession(),
            requestTimeout: 5
        )
    }

    private func jsonResponse(_ body: [String: Any], status: Int = 200) -> (URLRequest) throws -> (HTTPURLResponse, Data) {
        { request in
            let data = try JSONSerialization.data(withJSONObject: body)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }

    private func quickRequest(message: String = "Hey, what's up?", goal: Goal = .checkingIn) -> JudgmentRequest {
        JudgmentRequest(
            proposedMessage: message,
            goal: goal,
            context: .quick(QuickContext(whoTextedLast: .notSure, timeSinceLastMessage: .today, didHeRespond: .noQuestion, additionalNotes: ""))
        )
    }

    // MARK: - Local pre-filters short-circuit before any network call

    func testSafetyFlaggedMessageNeverHitsTheNetwork() async {
        MockURLProtocol.requestHandler = jsonResponse(["verdict": "send", "reason": "x", "recommended_action": "send", "rewrite_options": []])
        let provider = makeProvider()
        let request = quickRequest(message: "Answer me or I'll hurt you.")
        let result = await provider.judge(request)
        XCTAssertTrue(result.isSafetyRouted)
        XCTAssertEqual(MockURLProtocol.requestCount, 0)
    }

    func testMechanicalRuleNeverHitsTheNetwork() async {
        MockURLProtocol.requestHandler = jsonResponse(["verdict": "send", "reason": "x", "recommended_action": "send", "rewrite_options": []])
        let provider = makeProvider()
        // Repeated-contact mechanical rule fires on this notes text.
        let request = JudgmentRequest(
            proposedMessage: "Just checking if you got my message",
            goal: .getClarity,
            context: .quick(QuickContext(whoTextedLast: .me, timeSinceLastMessage: .fourPlusDays, didHeRespond: .no, additionalNotes: "This is the third time I've texted since he didn't answer"))
        )
        let result = await provider.judge(request)
        XCTAssertEqual(result.verdict, .dontSend)
        XCTAssertEqual(MockURLProtocol.requestCount, 0)
    }

    // MARK: - Valid remote responses

    func testValidResponseIsDecodedAndSurfacedDirectly() async {
        MockURLProtocol.requestHandler = jsonResponse([
            "verdict": "send",
            "reason": "This is warm and clear.",
            "recommended_action": "send",
            "rewrite_options": [],
        ])
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertEqual(result.verdict, .send)
        XCTAssertEqual(result.reason, "This is warm and clear.")
        XCTAssertEqual(result.recommendedAction, .send)
        XCTAssertFalse(result.isLocalFallback)
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }

    func testDontSendWireValueMapsToDontSendVerdict() async {
        MockURLProtocol.requestHandler = jsonResponse([
            "verdict": "dont_send",
            "reason": "This is hostile.",
            "recommended_action": "wait",
            "rewrite_options": ["A calmer version."],
        ])
        let provider = makeProvider()
        let result = await provider.judge(quickRequest(message: "hello gangster what the fuck is your problem"))
        XCTAssertEqual(result.verdict, .dontSend)
        XCTAssertEqual(result.recommendedAction, .wait)
        XCTAssertEqual(result.rewriteOptions.map(\.text), ["A calmer version."])
    }

    func testNeedContextWireValueMapsToNeedContextVerdict() async {
        MockURLProtocol.requestHandler = jsonResponse([
            "verdict": "need_context",
            "reason": "There isn't enough here to judge whether sending now makes sense.",
            "recommended_action": "add_context",
            "rewrite_options": [],
        ])
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertEqual(result.verdict, .needContext)
        XCTAssertEqual(result.recommendedAction, .addContext)
        XCTAssertTrue(result.rewriteOptions.isEmpty)
        XCTAssertFalse(result.isLocalFallback)
    }

    func testRewriteOptionsAreTrimmedFilteredAndCappedAtThree() async {
        MockURLProtocol.requestHandler = jsonResponse([
            "verdict": "rewrite",
            "reason": "Needs work.",
            "recommended_action": "rewrite",
            "rewrite_options": ["  Option one  ", "", "Option two", "Option three", "Option four"],
        ])
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertEqual(result.rewriteOptions.map(\.text), ["Option one", "Option two", "Option three"])
    }

    // MARK: - Invalid/failed responses fall back gracefully, never SEND

    func testUnknownVerdictValueTriggersLocalFallback() async {
        MockURLProtocol.requestHandler = jsonResponse([
            "verdict": "maybe",
            "reason": "x",
            "recommended_action": "send",
            "rewrite_options": [],
        ])
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertTrue(result.isLocalFallback)
        XCTAssertNotEqual(result.verdict, .send)
    }

    func testEmptyReasonTriggersLocalFallback() async {
        MockURLProtocol.requestHandler = jsonResponse([
            "verdict": "send",
            "reason": "   ",
            "recommended_action": "send",
            "rewrite_options": [],
        ])
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertTrue(result.isLocalFallback)
    }

    func testNon200StatusTriggersLocalFallback() async {
        MockURLProtocol.requestHandler = jsonResponse(["error": "model_unavailable"], status: 502)
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertTrue(result.isLocalFallback)
        XCTAssertNotEqual(result.verdict, .send)
    }

    func testNetworkFailureTriggersLocalFallback() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertTrue(result.isLocalFallback)
        XCTAssertNotEqual(result.verdict, .send)
        XCTAssertFalse(result.reason.isEmpty)
    }

    func testMalformedJSONTriggersLocalFallback() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("not json".utf8))
        }
        let provider = makeProvider()
        let result = await provider.judge(quickRequest())
        XCTAssertTrue(result.isLocalFallback)
        XCTAssertNotEqual(result.verdict, .send)
    }
}
