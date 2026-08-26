import XCTest
@testable import ShouldITextHim

/// Runs the full adversarial fixture suite against a REAL deployed
/// judgment endpoint — the only thing that can actually prove semantic
/// judgment quality, as opposed to `AdversarialSemanticFixtureTests`
/// (which proves the client plumbing is correct using a scripted mock).
///
/// This suite is a no-op in normal test runs (including CI) because no
/// live endpoint exists yet in this repository. To run it for real once
/// `server/` is deployed (see `server/README.md`):
///
///   1. Set the `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` environment variable
///      on the test scheme (Xcode: Edit Scheme -> Test -> Arguments ->
///      Environment Variables) to the deployed `/api/judge` URL.
///   2. Run this test target. Every fixture in `adversarialSemanticFixtures`
///      is sent to the real endpoint and graded against its
///      `idealVerdict`/`unacceptable` set.
///
/// A failure here is a genuine signal about prompt/model quality, not a
/// client bug — see `server/lib/prompt.ts` first.
final class RemoteAIJudgmentProviderLiveTests: XCTestCase {

    private var liveEndpoint: URL? {
        ProcessInfo.processInfo.environment["SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT"].flatMap(URL.init(string:))
    }

    func testAdversarialFixturesAgainstALiveDeployedEndpoint() async throws {
        guard let endpoint = liveEndpoint else {
            throw XCTSkip("Set SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT to run this against a real deployed judgment server.")
        }

        let provider = RemoteAIJudgmentProvider(endpoint: endpoint)
        var failures: [String] = []

        for fixture in adversarialSemanticFixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)
            if fixture.unacceptable.contains(result.verdict) {
                failures.append("[\(fixture.category) — \(fixture.name)] got \(result.verdict), unacceptable per: \(fixture.rationale)")
            }
        }

        XCTAssertTrue(failures.isEmpty, "Live semantic judgment failures:\n" + failures.joined(separator: "\n"))
    }
}
