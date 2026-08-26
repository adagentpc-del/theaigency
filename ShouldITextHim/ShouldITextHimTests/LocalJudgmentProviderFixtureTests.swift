import XCTest
@testable import ShouldITextHim

/// Product QA fixtures for `LocalJudgmentProvider` — the cases the fully
/// deterministic engine (safety + mechanical rules + fallback) can and
/// must resolve confidently and exactly, entirely on-device. Cases that
/// genuinely require reading tone/sarcasm/manipulation live in
/// `AdversarialSemanticFixtureTests` instead, since those are exactly the
/// cases this engine is no longer allowed to guess at (see
/// `DeterministicJudgmentRules` and `DECISIONS.md`).
private struct Fixture {
    let name: String
    let message: String
    let goal: Goal
    let context: ContextInput
    let expectedVerdict: Verdict
    let expectSafetyRouted: Bool
    let rationale: String

    init(
        _ name: String,
        message: String,
        goal: Goal,
        context: ContextInput,
        expectedVerdict: Verdict,
        expectSafetyRouted: Bool = false,
        rationale: String
    ) {
        self.name = name
        self.message = message
        self.goal = goal
        self.context = context
        self.expectedVerdict = expectedVerdict
        self.expectSafetyRouted = expectSafetyRouted
        self.rationale = rationale
    }
}

private func quick(
    who: WhoTextedLast,
    time: TimeSinceLastMessage,
    responded: DidHeRespond,
    notes: String = ""
) -> ContextInput {
    .quick(QuickContext(whoTextedLast: who, timeSinceLastMessage: time, didHeRespond: responded, additionalNotes: notes))
}

private let longRamblingParagraph = """
I've been thinking about this for a while now and I just wanted to write out everything that's been on my mind because there's a lot going on and I don't really know where to start but I guess I'll just try to explain the whole situation from the beginning since it feels important to give the full picture rather than leaving anything out because I think context really matters here and I want to make sure everything makes sense so please just bear with me while I go through all of it one piece at a time because there are a lot of small details that I think are actually pretty relevant to how I've been feeling about everything lately and where my head has been at recently and I know this is a lot to read all at once but I felt like I needed to get it all out there instead of holding it in any longer.
"""

private let fixtures: [Fixture] = [

    Fixture(
        "Unanswered direct question (canonical example)",
        message: "Hey stranger lol",
        goal: .getClarity,
        context: quick(who: .me, time: .oneToThreeDays, responded: .no),
        expectedVerdict: .dontSend,
        rationale: "A direct question already went unanswered; a casual check-in won't get clarity. Matches the product brief's worked example exactly."
    ),
    Fixture(
        "Repeated unanswered messages (notes-reported)",
        message: "Just checking if you got my message",
        goal: .getClarity,
        context: quick(who: .me, time: .fourPlusDays, responded: .no, notes: "This is the third time I've texted since he didn't answer"),
        expectedVerdict: .dontSend,
        rationale: "Self-reported repeated unanswered contact must never be nudged toward sending more."
    ),
    Fixture(
        "Obvious harassment / repeated contact",
        message: "Why aren't you answering me??? This is ridiculous",
        goal: .getClarity,
        context: quick(who: .me, time: .underAnHour, responded: .no, notes: "I've already texted him 6 times today and called twice"),
        expectedVerdict: .dontSend,
        rationale: "The app must never help escalate a pattern the user has already described as repeated, unanswered contact."
    ),
    Fixture(
        "Double texting",
        message: "hey did you see this?",
        goal: .checkingIn,
        context: quick(who: .me, time: .underAnHour, responded: .noQuestion),
        expectedVerdict: .sleep,
        rationale: "The user just texted very recently — sending again right away is a double-text risk."
    ),
    Fixture(
        "Breakup / big-decision language",
        message: "I think we should break up, this isn't working anymore.",
        goal: .getClosure,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        expectedVerdict: .sleep,
        rationale: "Big relationship decisions deserve a pause regardless of goal."
    ),
    Fixture(
        "Extremely long message",
        message: longRamblingParagraph,
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        expectedVerdict: .rewrite,
        rationale: "A wall of text needs trimming regardless of tone."
    ),
    Fixture(
        "Long silence, reopening contact",
        message: "Hey, it's been a while, thinking about you",
        goal: .checkingIn,
        context: quick(who: .me, time: .fourPlusDays, responded: .noQuestion),
        expectedVerdict: .sleep,
        rationale: "Reopening contact after a long gap deserves an intentional pause rather than a reflexive send."
    ),
    Fixture(
        "Ambiguous reciprocity while pushing plans",
        message: "So are we still on for Saturday??",
        goal: .makePlans,
        context: quick(who: .him, time: .today, responded: .sortOf),
        expectedVerdict: .rewrite,
        rationale: "A lukewarm prior response calls for a lower-pressure version, not confident pushing."
    ),
    Fixture(
        "Keyword-matched anger (still caught for free)",
        message: "You always ignore me, you're so pathetic, answer me!!!",
        goal: .getClarity,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        expectedVerdict: .dontSend,
        rationale: "Open hostility that happens to match the keyword list is still caught mechanically — the fix is that the ABSENCE of a match is no longer treated as a green light."
    ),
    Fixture(
        "Safety-sensitive input — violence threat",
        message: "Answer me or I'll hurt you.",
        goal: .getClarity,
        context: quick(who: .me, time: .today, responded: .noQuestion),
        expectedVerdict: .dontSend,
        expectSafetyRouted: true,
        rationale: "Safety routing must override everything else."
    ),
    Fixture(
        "Safety-sensitive input — self-harm",
        message: "If you don't call me back I want to end my life.",
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        expectedVerdict: .dontSend,
        expectSafetyRouted: true,
        rationale: "Self-harm language must be safety-routed regardless of goal."
    ),
    Fixture(
        "Safety-sensitive input — stalking",
        message: "I know where you live and I'll be outside your house tonight.",
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        expectedVerdict: .dontSend,
        expectSafetyRouted: true,
        rationale: "Stalking language must be safety-routed regardless of goal."
    ),
    Fixture(
        "Safety-sensitive input — coercion",
        message: "You better respond or you'll regret it.",
        goal: .getClarity,
        context: quick(who: .me, time: .today, responded: .no),
        expectedVerdict: .dontSend,
        expectSafetyRouted: true,
        rationale: "Coercive language must be safety-routed even though the context otherwise resembles the canonical unanswered-question case."
    ),
    Fixture(
        "Pasted conversation — self-reported repeated contact",
        message: "Hey, just wondering if you got my messages",
        goal: .getClarity,
        context: .conversation("Me: hey\nMe: hey are you around\nI already texted him twice this week with no reply"),
        expectedVerdict: .dontSend,
        rationale: "Even from a pasted conversation, a self-reported pattern of repeated unanswered contact must block another send."
    ),
    Fixture(
        "Pasted conversation — no special signal (honest fallback)",
        message: "Are you around this weekend?",
        goal: .makePlans,
        context: .conversation("Me: hey! how was your weekend?\nHim: so good, we should hang out again\nMe: yes!! when are you free?"),
        expectedVerdict: .rewrite,
        rationale: "The local engine deliberately does not deep-parse pasted conversations — it responds conservatively, never confidently, and never claims understanding it doesn't have."
    ),
    Fixture(
        "Pasted conversation — angry tone still overridden",
        message: "You always ignore me, this is so pathetic",
        goal: .checkingIn,
        context: .conversation("Me: hey\nHim: hey\nMe: hey are you around\nMe: hey again"),
        expectedVerdict: .dontSend,
        rationale: "Message-level tone rules apply the same way regardless of which context path was used."
    ),
    Fixture(
        "Neutral message, unanswered context",
        message: "Hey, how's it going?",
        goal: .checkingIn,
        context: quick(who: .me, time: .fourPlusDays, responded: .no),
        expectedVerdict: .sleep,
        rationale: "The exact same neutral message must NOT default to a confident answer when the user has been waiting days for a reply — the fix for the first reported defect."
    ),
]

final class LocalJudgmentProviderFixtureTests: XCTestCase {

    private let provider = LocalJudgmentProvider()

    func testAllFixtures() async {
        for fixture in fixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)

            XCTAssertEqual(
                result.verdict, fixture.expectedVerdict,
                "[\(fixture.name)] expected \(fixture.expectedVerdict) but got \(result.verdict). Rationale: \(fixture.rationale)"
            )
            XCTAssertEqual(result.isSafetyRouted, fixture.expectSafetyRouted, "[\(fixture.name)] isSafetyRouted mismatch")
            XCTAssertFalse(result.reason.isEmpty, "[\(fixture.name)] reason should never be empty")
        }
    }

    /// `LocalJudgmentProvider` must never return SEND IT, period — see
    /// `DeterministicJudgmentRules` and `FallbackJudgment`. Checked here
    /// across every fixture in this file as an explicit, always-on guard.
    func testNeverReturnsSend() async {
        for fixture in fixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)
            XCTAssertNotEqual(result.verdict, .send, "[\(fixture.name)] LocalJudgmentProvider must never return SEND IT")
        }
    }

    /// The mechanical layer should still meaningfully distinguish between
    /// dontSend/sleep/rewrite rather than collapsing to one answer.
    func testVerdictsAreDiverseAcrossNonSendOutcomes() async {
        var verdicts: Set<Verdict> = []
        for fixture in fixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)
            verdicts.insert(result.verdict)
        }
        XCTAssertEqual(verdicts, [.dontSend, .sleep, .rewrite])
    }
}
