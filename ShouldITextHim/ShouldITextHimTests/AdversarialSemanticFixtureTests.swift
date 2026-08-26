import XCTest
@testable import ShouldITextHim

final class AdversarialSemanticFixtureTests: XCTestCase {

    func testFixtureSuiteHasAtLeastFiftyScenariosAcrossAllRequiredCategories() {
        XCTAssertGreaterThanOrEqual(adversarialSemanticFixtures.count, 50)

        let requiredCategories: Set<String> = [
            "profanity", "euphemistic hostility", "sarcasm", "passive aggression",
            "guilt trip", "veiled threat", "manipulative affection", "accusatory question",
            "bizarre/chaotic", "polite harassment", "excessive follow-up", "calm boundary",
            "healthy directness", "genuine apology", "mutual flirting",
        ]
        let presentCategories = Set(adversarialSemanticFixtures.map(\.category))
        XCTAssertEqual(requiredCategories.subtracting(presentCategories), [], "Missing required adversarial categories")
    }

    /// The core guarantee: every adversarial fixture, run against the fully
    /// local/deterministic engine (no network, no live model), must not
    /// land on a verdict the fixture defines as a hard failure. For every
    /// hostile/manipulative fixture this means `LocalJudgmentProvider`
    /// must never return SEND IT — which now holds structurally (see
    /// `DeterministicJudgmentRules` and `FallbackJudgment`), regardless of
    /// whether the specific wording matches any keyword list. For the
    /// healthy fixtures it means the engine must never wrongly block a
    /// fine message with DON'T SEND IT.
    func testLocalProviderNeverHitsAnUnacceptableVerdict() async {
        let provider = LocalJudgmentProvider()
        for fixture in adversarialSemanticFixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)
            XCTAssertFalse(
                fixture.unacceptable.contains(result.verdict),
                "[\(fixture.category) — \(fixture.name)] got \(result.verdict), which is unacceptable (\(fixture.unacceptable)). Rationale: \(fixture.rationale)"
            )
        }
    }

    /// `LocalJudgmentProvider` must never return SEND IT for ANY fixture
    /// whose category represents a real product concern (i.e. every
    /// fixture where `.send` is unacceptable) — restated as its own
    /// assertion for clarity/searchability, since this is the literal
    /// regression this whole fixture suite exists to guard.
    func testLocalProviderNeverSendsHostileOrManipulativeMessages() async {
        let provider = LocalJudgmentProvider()
        let hostileFixtures = adversarialSemanticFixtures.filter { $0.unacceptable.contains(.send) }
        XCTAssertGreaterThan(hostileFixtures.count, 30, "Expected the majority of adversarial fixtures to be hostile/manipulative cases")

        for fixture in hostileFixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)
            XCTAssertNotEqual(result.verdict, .send, "[\(fixture.name)] must never be SEND IT")
        }
    }
}

/// Proves `RemoteAIJudgmentProvider` correctly decodes, validates, and
/// surfaces a semantic verdict end-to-end using `MockURLProtocol` —
/// i.e. that the CLIENT plumbing is correct, not that a live model will
/// actually produce these verdicts (that requires
/// `RemoteAIJudgmentProviderLiveTests` against a real deployed endpoint).
/// Restricted to fixtures verified not to be resolved by a local
/// safety/mechanical short-circuit, since those never reach the network
/// at all — see `RemoteAIJudgmentProviderTests` for that behavior.
final class AdversarialSemanticFixtureMockedProviderTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    private static let wireVerdicts: [Verdict: String] = [
        .send: "send", .rewrite: "rewrite", .sleep: "sleep", .dontSend: "dont_send", .needContext: "need_context",
    ]

    private let representativeFixtureNames: Set<String> = [
        "Veiled threat, ominous warning",
        "Veiled threat, escalation warning",
        "Manipulative affection, love as pressure",
        "Guilt trip, keeping score",
        "Polite harassment, apologetic repetition",
        "Chaotic, rambling non-sequitur",
        "Calm boundary, needing space",
        "Healthy directness, clear ask",
        "Genuine apology, taking responsibility",
        "Mutual flirting, eager follow-up",
    ]

    func testRemoteProviderSurfacesTheAIsVerdictForRepresentativeFixtures() async throws {
        let fixtures = adversarialSemanticFixtures.filter { representativeFixtureNames.contains($0.name) }
        XCTAssertEqual(fixtures.count, representativeFixtureNames.count, "A named representative fixture was renamed or removed")

        for fixture in fixtures {
            MockURLProtocol.reset()
            let wireVerdict = try XCTUnwrap(Self.wireVerdicts[fixture.idealVerdict])
            MockURLProtocol.requestHandler = { request in
                let body: [String: Any] = [
                    "verdict": wireVerdict,
                    "reason": "Scripted response for test fixture.",
                    "recommended_action": fixture.idealVerdict == .send ? "send" : "rewrite",
                    "rewrite_options": [],
                ]
                let data = try JSONSerialization.data(withJSONObject: body)
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }

            let provider = RemoteAIJudgmentProvider(
                endpoint: URL(string: "https://test.invalid/api/judge")!,
                urlSession: MockURLProtocol.makeSession()
            )
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)

            XCTAssertEqual(
                result.verdict, fixture.idealVerdict,
                "[\(fixture.name)] expected the client to surface the AI's verdict (\(fixture.idealVerdict)) but got \(result.verdict) — did a local rule short-circuit before the network call?"
            )
            XCTAssertFalse(result.isLocalFallback)
            XCTAssertEqual(MockURLProtocol.requestCount, 1, "[\(fixture.name)] expected exactly one network call")
        }
    }
}
