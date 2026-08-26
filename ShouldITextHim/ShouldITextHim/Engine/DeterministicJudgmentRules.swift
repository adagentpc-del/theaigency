import Foundation

/// "Layer 2" of the judgment architecture: obvious, explainable, mechanical
/// rules that combine the user's stated `Goal` with `MessageSignals` (the
/// proposed text) and `ContextSignals` (what happened before it).
///
/// Critical invariant, changed after a second QA-found defect: **no rule
/// here ever returns `.send`.** A message like "hello gangster what the
/// fuck is your problem" doesn't match any hostility keyword, so a
/// keyword-based rule set can never be trusted to *confidently clear* a
/// message — it can only be trusted to catch specific, well-understood
/// red flags. Only genuine semantic judgment (`RemoteAIJudgmentProvider`)
/// or an explicit, structural positive fact should ever produce SEND IT;
/// everything below either raises a concern or defers. See `DECISIONS.md`
/// for the full rationale and `AI_SAFETY.md` for how this composes with
/// safety routing and repeated-contact guarding.
///
/// Rules are ordered highest-priority first and the first match wins.
/// Returns `nil` when no rule confidently applies, signaling the caller
/// to defer to semantic judgment (`RemoteAIJudgmentProvider`) or, if that
/// is unavailable, to `FallbackJudgment`.
enum DeterministicJudgmentRules {
    static func evaluate(goal: Goal, message: MessageSignals, context: ContextSignals) -> JudgmentResult? {

        // 1. The user has already said (in their own words) that they've
        // reached out more than once without a response. Never help send
        // another message on top of that — this is the app's hard line
        // against encouraging repeated unwanted contact.
        if context.mentionsRepeatedContact {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "You've already reached out more than once without a response. Sending another message right now risks feeling like pressure instead of connection — give it real space."
            )
        }

        // 2. The user just sent a message very recently and is
        // considering sending another one already.
        if context.veryRecentSelfContact {
            return JudgmentResult(
                verdict: .sleep,
                reason: "You just texted very recently and haven't heard back yet. Give it a little more time before sending anything else."
            )
        }

        // 3. The canonical "clarity" failure mode: they already asked a
        // direct question, got no answer, and the new message is just
        // casual filler rather than another direct ask. Purely structural
        // (context flag + presence of a question mark), not tone-guessing.
        if goal == .getClarity && context.hasPendingUnansweredQuestion && !message.endsWithQuestion {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "You already asked a direct question and haven't gotten an answer. Another casual check-in probably won't get you the clarity you're looking for."
            )
        }

        // 4. Breakup/ultimatum-level language deserves a pause regardless
        // of goal.
        if message.bigDecisionScore > 0 {
            return JudgmentResult(
                verdict: .sleep,
                reason: "This reads like a big-relationship-decision text, not a quick one. Sleep on it and see if it still feels true tomorrow."
            )
        }

        // 5. Very long messages read as overthinking regardless of intent
        // — pure word count, no tone judgment required.
        if message.wordCount > 120 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "This is a lot of message for a text. Trim it to the one thing you actually want them to know."
            )
        }

        // 6. It's been a real stretch since they last heard from the
        // other person, and there's no positive signal pulling them back
        // in — worth being intentional rather than reflexive.
        if context.longSinceContact && !context.positiveReciprocity {
            return JudgmentResult(
                verdict: .sleep,
                reason: "It's been a while since you last heard from them. Worth being intentional about this one instead of sending on impulse."
            )
        }

        // 7. Strong keyword-matched hostility. This catches *some* angry
        // messages for free, but it is explicitly NOT relied upon as the
        // primary hostility check — anything it misses (sarcasm,
        // profanity outside this list, veiled threats, manipulative
        // affection, etc.) is exactly what semantic judgment is for.
        if message.angerScore >= 2 {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "This is coming from anger, not clarity. You'll want different words once you've cooled off."
            )
        }

        // 8. Anxious/pressuring tone (best-effort keyword signal).
        if message.anxietyScore >= 3 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "This reads a little anxious — lots of pressure, not much confidence. Say less and let it breathe."
            )
        }

        // 9. Mild tone issues (best-effort keyword signal).
        if message.angerScore == 1 || message.anxietyScore == 2 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "The core of this is fine, the delivery needs a pass. Tighten the tone before it goes out."
            )
        }

        // 10. Their last response was lukewarm and this message is
        // pushing for more plans or more clarity — ease off a little.
        if context.ambiguousReciprocity && (goal == .makePlans || goal == .getClarity) {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "Their last response was lukewarm. Consider a lower-pressure version of this before pushing further."
            )
        }

        return nil
    }
}
