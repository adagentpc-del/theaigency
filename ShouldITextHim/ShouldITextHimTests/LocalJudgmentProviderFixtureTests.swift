import XCTest
@testable import ShouldITextHim

/// Product QA fixture suite for `LocalJudgmentProvider`.
///
/// This is the regression test for the defect reported after the first
/// build: the old engine judged the proposed message in isolation and
/// defaulted to SEND IT far too often. Every fixture below pairs a
/// proposed message with a *goal* and *context*, because that's what the
/// redesigned engine actually reasons about — several fixtures reuse the
/// exact same proposed message with different context to prove the
/// verdict now depends on more than the message text alone (see
/// `testIdenticalMessageProducesDifferentVerdictsForDifferentContext`).
///
/// `acceptable`/`unacceptable` are intentionally sets rather than a single
/// expected verdict where more than one outcome is legitimately fine — a
/// deterministic heuristic engine shouldn't be pinned to one exact
/// phrasing decision where a reasonable person could land on either of
/// two verdicts, but there is always at least one verdict that would be a
/// product failure if returned.
private struct Fixture {
    let name: String
    let message: String
    let goal: Goal
    let context: ContextInput
    let acceptable: Set<Verdict>
    let unacceptable: Set<Verdict>
    let rationale: String
    let expectSafetyRouted: Bool

    init(
        _ name: String,
        message: String,
        goal: Goal,
        context: ContextInput,
        acceptable: Set<Verdict>,
        unacceptable: Set<Verdict>,
        rationale: String,
        expectSafetyRouted: Bool = false
    ) {
        self.name = name
        self.message = message
        self.goal = goal
        self.context = context
        self.acceptable = acceptable
        self.unacceptable = unacceptable
        self.rationale = rationale
        self.expectSafetyRouted = expectSafetyRouted
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

private let longApologyParagraph = """
I am so sorry, I really am, and I know saying sorry probably doesn't fix anything but I wanted to explain everything that happened because I think if you understood the whole situation from start to finish you might see it differently, and I keep going over it in my head again and again trying to figure out where it went wrong and I just want you to know that I never meant for any of this to happen and I feel terrible about it and I hope you can find some way to forgive me eventually even if it takes time because I really do care and I am sorry, truly, for all of it, and I just needed you to know that before anything else, and I promise I'm going to do better going forward because this really has been sitting heavy on me since it happened and I didn't want another day to go by without saying all of this clearly.
"""

private let fixtures: [Fixture] = [

    Fixture(
        "Healthy flirting",
        message: "Been thinking about you today — what are you up to this weekend?",
        goal: .flirt,
        context: quick(who: .him, time: .underAnHour, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Warm tone, goal is flirt, and the other person has been actively responsive."
    ),

    Fixture(
        "Mutual conversation",
        message: "This was fun, let's do it again soon?",
        goal: .makePlans,
        context: quick(who: .notSure, time: .today, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Positive reciprocity, no red flags in the message."
    ),

    Fixture(
        "Making plans",
        message: "Are you free Friday for dinner?",
        goal: .makePlans,
        context: quick(who: .him, time: .underAnHour, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Direct, low-pressure ask with a responsive other side."
    ),

    Fixture(
        "Double texting",
        message: "hey did you see this?",
        goal: .checkingIn,
        context: quick(who: .me, time: .underAnHour, responded: .noQuestion),
        acceptable: [.sleep, .dontSend],
        unacceptable: [.send],
        rationale: "The user just texted very recently — sending again right away is a double-text risk."
    ),

    Fixture(
        "Unanswered direct question (canonical example)",
        message: "Hey stranger lol",
        goal: .getClarity,
        context: quick(who: .me, time: .oneToThreeDays, responded: .no),
        acceptable: [.dontSend],
        unacceptable: [.send],
        rationale: "A direct question already went unanswered; a casual check-in won't get clarity. Matches the product brief's worked example exactly."
    ),

    Fixture(
        "Repeated unanswered messages",
        message: "Just checking if you got my message",
        goal: .getClarity,
        context: quick(who: .me, time: .fourPlusDays, responded: .no, notes: "This is the third time I've texted since he didn't answer"),
        acceptable: [.dontSend, .sleep],
        unacceptable: [.send],
        rationale: "Self-reported repeated unanswered contact should never be nudged toward sending more."
    ),

    Fixture(
        "Apology",
        message: "I was out of line yesterday, I'm sorry, I shouldn't have said that.",
        goal: .apologize,
        context: quick(who: .me, time: .today, responded: .sortOf),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Calm, direct, genuine apology with no hedging."
    ),

    Fixture(
        "Legitimate boundary setting",
        message: "I need us to stop texting after midnight, it's not working for me.",
        goal: .setBoundary,
        context: quick(who: .him, time: .today, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "A calm, clearly-stated boundary must never be treated the same as an angry message."
    ),

    Fixture(
        "Angry message",
        message: "You always ignore me, you're so pathetic, answer me!!!",
        goal: .getClarity,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.dontSend],
        unacceptable: [.send],
        rationale: "Open hostility should never be sent, regardless of stated goal."
    ),

    Fixture(
        "Passive aggressive message",
        message: "wow must be nice being that busy lol. anyway.",
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.rewrite, .dontSend],
        unacceptable: [.send],
        rationale: "Passive-aggression reads as friendly on the surface but isn't safe to send as-is."
    ),

    Fixture(
        "Extremely long emotional paragraph",
        message: longRamblingParagraph,
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.rewrite],
        unacceptable: [.send],
        rationale: "A wall of text needs trimming regardless of tone."
    ),

    Fixture(
        "Late-night impulsive text",
        message: "I know it's 2am and this is probably a bad idea but I can't stop thinking about you, please call me",
        goal: .flirt,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.rewrite, .sleep],
        unacceptable: [.send],
        rationale: "Self-described impulsive late-night sends deserve a second look."
    ),

    Fixture(
        "Closure",
        message: "I just want to know where things ended up, no pressure either way.",
        goal: .getClosure,
        context: quick(who: .notSure, time: .fourPlusDays, responded: .noQuestion),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Calm, low-pressure closure request with nothing left hanging."
    ),

    Fixture(
        "Ex contact / reopening after long silence",
        message: "Hey, it's been a while, thinking about you",
        goal: .checkingIn,
        context: quick(who: .me, time: .fourPlusDays, responded: .noQuestion, notes: "Haven't talked in months"),
        acceptable: [.sleep],
        unacceptable: [.send, .dontSend],
        rationale: "Reopening contact after a long gap deserves an intentional pause, not a reflexive send or an outright no."
    ),

    Fixture(
        "Ambiguous response",
        message: "So... are we still doing something this weekend or nah?",
        goal: .getClarity,
        context: quick(who: .him, time: .today, responded: .sortOf),
        acceptable: [.send, .rewrite],
        unacceptable: [.dontSend],
        rationale: "A lukewarm prior response calls for a lower-pressure version, not a block."
    ),

    Fixture(
        "Enthusiastic reciprocal response",
        message: "Yes! Let's do Saturday, I'm excited",
        goal: .makePlans,
        context: quick(who: .him, time: .underAnHour, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend, .sleep],
        rationale: "Clear mutual enthusiasm — no reason to hesitate."
    ),

    Fixture(
        "Dry response",
        message: "So are we still on for Saturday??",
        goal: .makePlans,
        context: quick(who: .him, time: .today, responded: .sortOf),
        acceptable: [.rewrite, .sleep],
        unacceptable: [.send],
        rationale: "Pushing plans after a lukewarm reply deserves a softer version."
    ),

    Fixture(
        "Cancellation",
        message: "Hey, I actually can't make it tonight, so sorry, can we reschedule?",
        goal: .makePlans,
        context: quick(who: .him, time: .today, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "A polite, ordinary cancellation with a responsive other side."
    ),

    Fixture(
        "Rescheduling",
        message: "Can we move dinner to Saturday instead? Wednesday doesn't work anymore.",
        goal: .makePlans,
        context: quick(who: .me, time: .today, responded: .noQuestion),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Ordinary, low-stakes logistics message with nothing concerning."
    ),

    Fixture(
        "First message (cold open)",
        message: "Hey! I got your number from Sarah, wanted to say hi 🙂",
        goal: .flirt,
        context: quick(who: .notSure, time: .fourPlusDays, responded: .noQuestion),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Friendly, low-pressure cold open with nothing risky in it."
    ),

    Fixture(
        "Checking in after reasonable time",
        message: "Hey! How'd the interview go?",
        goal: .checkingIn,
        context: quick(who: .him, time: .oneToThreeDays, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "Friendly follow-up with someone who's been responsive."
    ),

    Fixture(
        "Obvious harassment / repeated contact",
        message: "Why aren't you answering me??? This is ridiculous",
        goal: .getClarity,
        context: quick(who: .me, time: .underAnHour, responded: .no, notes: "I've already texted him 6 times today and called twice"),
        acceptable: [.dontSend],
        unacceptable: [.send],
        rationale: "The app must never help escalate a pattern the user has already described as repeated, unanswered contact."
    ),

    Fixture(
        "Safety-sensitive input — violence threat",
        message: "Answer me or I'll hurt you.",
        goal: .getClarity,
        context: quick(who: .me, time: .today, responded: .noQuestion),
        acceptable: [.dontSend],
        unacceptable: [.send, .sleep, .rewrite],
        rationale: "Safety routing must override goal/context reasoning entirely.",
        expectSafetyRouted: true
    ),

    Fixture(
        "Safety-sensitive input — self-harm",
        message: "If you don't call me back I want to end my life.",
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.dontSend],
        unacceptable: [.send, .sleep, .rewrite],
        rationale: "Self-harm language must be safety-routed regardless of goal.",
        expectSafetyRouted: true
    ),

    Fixture(
        "Safety-sensitive input — stalking",
        message: "I know where you live and I'll be outside your house tonight.",
        goal: .checkingIn,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.dontSend],
        unacceptable: [.send, .sleep, .rewrite],
        rationale: "Stalking language must be safety-routed regardless of goal.",
        expectSafetyRouted: true
    ),

    Fixture(
        "Safety-sensitive input — coercion",
        message: "You better respond or you'll regret it.",
        goal: .getClarity,
        context: quick(who: .me, time: .today, responded: .no),
        acceptable: [.dontSend],
        unacceptable: [.send, .sleep, .rewrite],
        rationale: "Coercive language must be safety-routed even though the context otherwise resembles the canonical unanswered-question case.",
        expectSafetyRouted: true
    ),

    Fixture(
        "Repeated apology / groveling long message",
        message: longApologyParagraph,
        goal: .apologize,
        context: quick(who: .me, time: .today, responded: .sortOf),
        acceptable: [.rewrite],
        unacceptable: [.send],
        rationale: "Even a genuine apology needs trimming at this length."
    ),

    Fixture(
        "Boundary goal with insulting tone",
        message: "you're pathetic, stop bothering me",
        goal: .setBoundary,
        context: quick(who: .notSure, time: .today, responded: .noQuestion),
        acceptable: [.rewrite, .dontSend],
        unacceptable: [.send],
        rationale: "Stating a goal of 'set a boundary' does not excuse an insulting delivery — goal alone must never force SEND IT."
    ),

    Fixture(
        "Neutral message, positive context",
        message: "Hey, how's it going?",
        goal: .checkingIn,
        context: quick(who: .him, time: .oneToThreeDays, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend, .sleep],
        rationale: "Half of the identical-message contrast pair below — positive context supports sending."
    ),

    Fixture(
        "Neutral message, unanswered context (contrast pair)",
        message: "Hey, how's it going?",
        goal: .checkingIn,
        context: quick(who: .me, time: .fourPlusDays, responded: .no),
        acceptable: [.sleep, .rewrite],
        unacceptable: [.send],
        rationale: "The other half of the contrast pair: the exact same message, but the user has been waiting days for a reply — this must NOT default to SEND IT."
    ),

    Fixture(
        "Get clarity with a genuinely positive recent response",
        message: "Hey, are we still on for Saturday?",
        goal: .getClarity,
        context: quick(who: .him, time: .today, responded: .yes),
        acceptable: [.send],
        unacceptable: [.dontSend],
        rationale: "A direct question aimed at someone who has been responsive should be sendable."
    ),

    Fixture(
        "Pasted conversation — self-reported repeated contact",
        message: "Hey, just wondering if you got my messages",
        goal: .getClarity,
        context: .conversation("Me: hey\nMe: hey are you around\nI already texted him twice this week with no reply"),
        acceptable: [.dontSend],
        unacceptable: [.send],
        rationale: "Even from a pasted conversation, a self-reported pattern of repeated unanswered contact must block another send."
    ),

    Fixture(
        "Pasted conversation — no special signal (honest fallback)",
        message: "Are you around this weekend?",
        goal: .makePlans,
        context: .conversation("Me: hey! how was your weekend?\nHim: so good, we should hang out again\nMe: yes!! when are you free?"),
        acceptable: [.rewrite],
        unacceptable: [.dontSend],
        rationale: "The local engine deliberately does not deep-parse pasted conversations (see DECISIONS.md) — it should respond conservatively, not confidently, and never claim understanding it doesn't have."
    ),

    Fixture(
        "Pasted conversation — angry tone still overridden",
        message: "You always ignore me, this is so pathetic",
        goal: .checkingIn,
        context: .conversation("Me: hey\nHim: hey\nMe: hey are you around\nMe: hey again"),
        acceptable: [.dontSend],
        unacceptable: [.send],
        rationale: "Message-level tone rules apply the same way regardless of which context path was used."
    ),
]

final class LocalJudgmentProviderFixtureTests: XCTestCase {

    private let provider = LocalJudgmentProvider()

    func testAllFixtures() async {
        for fixture in fixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)

            XCTAssertTrue(
                fixture.acceptable.contains(result.verdict),
                "[\(fixture.name)] expected one of \(fixture.acceptable) but got \(result.verdict). Rationale: \(fixture.rationale)"
            )
            XCTAssertFalse(
                fixture.unacceptable.contains(result.verdict),
                "[\(fixture.name)] verdict \(result.verdict) is explicitly unacceptable. Rationale: \(fixture.rationale)"
            )
            XCTAssertEqual(
                result.isSafetyRouted, fixture.expectSafetyRouted,
                "[\(fixture.name)] isSafetyRouted mismatch"
            )
            XCTAssertFalse(result.reason.isEmpty, "[\(fixture.name)] reason should never be empty")
        }
    }

    /// The core regression test: an identical proposed message must be
    /// able to produce different verdicts depending on context. This is
    /// the exact defect that was reported — the old engine ignored goal
    /// and context and would return the same verdict for both cases.
    func testIdenticalMessageProducesDifferentVerdictsForDifferentContext() async {
        let positive = fixtures.first { $0.name == "Neutral message, positive context" }!
        let waiting = fixtures.first { $0.name == "Neutral message, unanswered context (contrast pair)" }!
        XCTAssertEqual(positive.message, waiting.message)

        let positiveResult = await provider.judge(
            JudgmentRequest(proposedMessage: positive.message, goal: positive.goal, context: positive.context)
        )
        let waitingResult = await provider.judge(
            JudgmentRequest(proposedMessage: waiting.message, goal: waiting.goal, context: waiting.context)
        )

        XCTAssertNotEqual(positiveResult.verdict, waitingResult.verdict)
        XCTAssertEqual(positiveResult.verdict, .send)
        XCTAssertNotEqual(waitingResult.verdict, .send)
    }

    /// A provider that returns SEND IT for most scenarios is a failed
    /// implementation even if every fixture individually "passes" via a
    /// loose acceptable set. This asserts real diversity across the
    /// fixture suite.
    func testVerdictsAreMeaningfullyDiverseAcrossFixtures() async {
        var counts: [Verdict: Int] = [:]
        for fixture in fixtures {
            let request = JudgmentRequest(proposedMessage: fixture.message, goal: fixture.goal, context: fixture.context)
            let result = await provider.judge(request)
            counts[result.verdict, default: 0] += 1
        }

        XCTAssertGreaterThanOrEqual(
            counts.keys.count, 3,
            "Expected at least 3 distinct verdicts across the fixture suite, got \(counts)"
        )

        let total = fixtures.count
        let sendCount = counts[.send] ?? 0
        XCTAssertLessThan(
            Double(sendCount) / Double(total), 0.6,
            "SEND IT should not dominate the fixture suite (got \(sendCount)/\(total)) — this is the exact defect being regression-tested"
        )
    }
}
