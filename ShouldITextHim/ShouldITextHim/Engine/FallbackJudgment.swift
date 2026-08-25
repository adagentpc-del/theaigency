import Foundation

/// "Layer 3" placeholder: what to do when no deterministic rule in
/// `DeterministicJudgmentRules` confidently applies. This is the seam
/// where the fixed defect used to live — the old engine defaulted to
/// SEND IT whenever it ran out of keyword matches, regardless of what the
/// user had actually told it. This fallback is deliberately conservative
/// and still context-aware instead of defaulting to confidence:
///
/// - A pasted conversation always gets an honest, moderate response,
///   because the local provider does not deeply parse free text (see
///   `ContextSignals`). This is exactly the gap a future
///   `RemoteAIJudgmentProvider` would close (`API_CONTRACT.md`).
/// - Quick context with no red flags and a warm or clean/unhanging
///   message can still land on SEND IT — but only because the context
///   actually supports it, not by default.
enum FallbackJudgment {
    static func decide(goal: Goal, message: MessageSignals, context: ContextSignals) -> JudgmentResult {
        if context.isFromPastedConversation {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "We can only read the surface of a pasted conversation right now — the message itself looks fine, but double-check it actually fits what happened before you send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if message.warmthScore > 0 {
            return JudgmentResult(
                verdict: .send,
                reason: "Clear, low-drama, and fits what you're going for. Send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if context.noQuestionPending {
            return JudgmentResult(
                verdict: .send,
                reason: "Nothing here raises a flag, and there's no unanswered question hanging over it. Send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        return JudgmentResult(
            verdict: .rewrite,
            reason: "This isn't a clear yes from what you've told us — tighten it up so it can't be misread before you send it.",
            riskFlags: [],
            isSafetyRouted: false
        )
    }
}
