import Foundation

/// The last-resort, fully-local result when neither a mechanical rule
/// (`DeterministicJudgmentRules`) nor semantic AI judgment
/// (`RemoteAIJudgmentProvider`) is available or confident. This is the
/// exact seam where a second QA-found defect used to live: it previously
/// returned SEND IT whenever no rule had fired, which meant *absence of a
/// detected problem* was being treated as *evidence the message was fine*
/// — the opposite of true. A local, keyword-based engine cannot verify a
/// message is safe to send; it can only fail to find a reason not to.
/// Those are not the same thing, so this fallback **never returns
/// `.send`.** See `DECISIONS.md` for the full rationale.
enum FallbackJudgment {
    static func decide(goal: Goal, message: MessageSignals, context: ContextSignals) -> JudgmentResult {
        if context.isFromPastedConversation {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "We can only read the surface of a pasted conversation right now — double-check this actually fits what happened before you send it.",
                isLocalFallback: true
            )
        }

        return JudgmentResult(
            verdict: .rewrite,
            reason: "I can't confidently judge this without a fuller read on it. Take another look before sending, or try again in a moment.",
            isLocalFallback: true
        )
    }
}
