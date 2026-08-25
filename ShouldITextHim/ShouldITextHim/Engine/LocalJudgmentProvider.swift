import Foundation

/// The on-device `JudgmentProvider`. Composes the three layers described
/// in `DECISIONS.md`:
///
/// 1. **Deterministic safety rules** (`SafetyScanner`) — always run first,
///    over the proposed message and any free text the user provided as
///    context, and always win if triggered.
/// 2. **Deterministic obvious judgment** (`MessageSignals` +
///    `ContextSignals` + `DeterministicJudgmentRules`) — goal-and-context
///    aware rules for the cases that don't need real semantic
///    understanding to get right.
/// 3. **Semantic judgment** (`FallbackJudgment`, today) — the seam a
///    future `RemoteAIJudgmentProvider` would occupy for the messier,
///    more ambiguous cases layer 2 can't confidently resolve.
struct LocalJudgmentProvider: JudgmentProvider {
    func judge(_ request: JudgmentRequest) async -> JudgmentResult {
        let riskFlags = SafetyScanner.scan(safetyScanText(for: request))
        if !riskFlags.isEmpty {
            return SafetyScanner.safeResponse(for: riskFlags)
        }

        let message = MessageSignals(text: request.proposedMessage)
        let context = ContextSignals(context: request.context)

        if let result = DeterministicJudgmentRules.evaluate(goal: request.goal, message: message, context: context) {
            return result
        }

        return FallbackJudgment.decide(goal: request.goal, message: message, context: context)
    }

    /// Combines every piece of free text the user provided so the safety
    /// scan can't be bypassed by putting risky language in the context
    /// instead of the proposed message.
    private func safetyScanText(for request: JudgmentRequest) -> String {
        var parts = [request.proposedMessage]
        switch request.context {
        case .conversation(let text):
            parts.append(text)
        case .quick(let quick):
            parts.append(quick.additionalNotes)
        }
        return parts.joined(separator: "\n")
    }
}
