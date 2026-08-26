import Foundation

/// The fully on-device `JudgmentProvider`. In production this is used two
/// ways: as the pre-AI safety/mechanical filter inside
/// `RemoteAIJudgmentProvider`, and standalone as the offline/error
/// fallback when the network is unavailable. It is never the app's
/// primary source of a SEND IT verdict — see the invariant documented on
/// `DeterministicJudgmentRules` and `FallbackJudgment`.
///
/// Composes three layers (see `DECISIONS.md`):
///
/// 1. **Deterministic safety rules** (`SafetyScanner`) — always run first,
///    over every piece of free text the user provided, and always win.
/// 2. **Deterministic mechanical judgment** (`MessageSignals` +
///    `ContextSignals` + `DeterministicJudgmentRules`) — goal-and-context
///    aware rules for cases that don't need real semantic understanding
///    to get right. Never produces SEND IT.
/// 3. **Conservative fallback** (`FallbackJudgment`) — used when layer 2
///    has no confident rule. Never produces SEND IT either; only genuine
///    semantic judgment (`RemoteAIJudgmentProvider`) can.
struct LocalJudgmentProvider: JudgmentProvider {
    func judge(_ request: JudgmentRequest) async -> JudgmentResult {
        let riskFlags = SafetyScanner.scan(request.combinedFreeText)
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
}
