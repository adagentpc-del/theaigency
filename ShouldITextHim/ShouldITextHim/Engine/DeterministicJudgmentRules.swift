import Foundation

/// "Layer 2" of the judgment architecture: obvious, explainable rules that
/// combine the user's stated `Goal` with `MessageSignals` (the proposed
/// text) and `ContextSignals` (what happened before it). This is where
/// the redesigned engine actually fixes the "returns SEND IT for almost
/// everything" defect — every rule here reasons about goal *and* context
/// together, never the message in isolation.
///
/// Rules are ordered highest-priority first and the first match wins.
/// Returns `nil` when no rule confidently applies, signaling the caller
/// to fall back to `FallbackJudgment` (the seam where a future
/// `RemoteAIJudgmentProvider` would instead take over — see
/// `API_CONTRACT.md`).
enum DeterministicJudgmentRules {
    static func evaluate(goal: Goal, message: MessageSignals, context: ContextSignals) -> JudgmentResult? {

        // 1. The user has already said (in their own words) that they've
        // reached out more than once without a response. Never help send
        // another message on top of that — this is the app's hard line
        // against encouraging repeated unwanted contact.
        if context.mentionsRepeatedContact {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "You've already reached out more than once without a response. Sending another message right now risks feeling like pressure instead of connection — give it real space.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 2. The user just sent a message very recently and is
        // considering sending another one already.
        if context.veryRecentSelfContact {
            return JudgmentResult(
                verdict: .sleep,
                reason: "You just texted very recently and haven't heard back yet. Give it a little more time before sending anything else.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 3. Clear anger/hostility always overrides the stated goal.
        if message.angerScore >= 2 {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "This is coming from anger, not clarity. You'll want different words once you've cooled off.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 4. The canonical "clarity" failure mode: they already asked a
        // direct question, got no answer, and the new message is just
        // casual filler rather than another direct ask.
        if goal == .getClarity && context.hasPendingUnansweredQuestion && !message.endsWithQuestion {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "You already asked a direct question and haven't gotten an answer. Another casual check-in probably won't get you the clarity you're looking for.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 5. Breakup/ultimatum-level language deserves a pause regardless
        // of goal.
        if message.bigDecisionScore > 0 {
            return JudgmentResult(
                verdict: .sleep,
                reason: "This reads like a big-relationship-decision text, not a quick one. Sleep on it and see if it still feels true tomorrow.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 6. Very long messages read as overthinking regardless of intent.
        if message.wordCount > 120 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "This is a lot of message for a text. Trim it to the one thing you actually want them to know.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 7. It's been a real stretch since they last heard from the
        // other person, and there's no positive signal pulling them back
        // in — worth being intentional rather than reflexive.
        if context.longSinceContact && !context.positiveReciprocity {
            return JudgmentResult(
                verdict: .sleep,
                reason: "It's been a while since you last heard from them. Worth being intentional about this one instead of sending on impulse.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 8. Anxious/pressuring tone.
        if message.anxietyScore >= 3 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "This reads a little anxious — lots of pressure, not much confidence. Say less and let it breathe.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 9. Mild tone issues.
        if message.angerScore == 1 || message.anxietyScore == 2 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "The core of this is fine, the delivery needs a pass. Tighten the tone before it goes out.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 10. A calm boundary is exactly what it should be — validate it
        // rather than falling through to a generic rule.
        if goal == .setBoundary && message.angerScore == 0 {
            return JudgmentResult(
                verdict: .send,
                reason: "This is calm and direct about what you need — that's exactly what a boundary should sound like.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 11. A calm, direct apology.
        if goal == .apologize && message.angerScore == 0 && message.anxietyScore == 0 {
            return JudgmentResult(
                verdict: .send,
                reason: "This reads like a genuine, direct apology — no hedging, no blame-shifting. Send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 12. A calm closure request with nothing left hanging.
        if goal == .getClosure && message.angerScore == 0 && message.anxietyScore == 0 && !context.hasPendingUnansweredQuestion {
            return JudgmentResult(
                verdict: .send,
                reason: "This is a calm, clear ask for closure without picking a fight. Send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 13. They've been engaged and responsive, and nothing here is a
        // red flag.
        if context.positiveReciprocity && message.angerScore == 0 {
            return JudgmentResult(
                verdict: .send,
                reason: "They've been engaged and responsive, and this fits that. Send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        // 14. Their last response was lukewarm and this message is
        // pushing for more plans or more clarity — ease off a little.
        if context.ambiguousReciprocity && (goal == .makePlans || goal == .getClarity) {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "Their last response was lukewarm. Consider a lower-pressure version of this before pushing further.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        return nil
    }
}
