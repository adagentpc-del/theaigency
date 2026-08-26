import Foundation

/// Categories the safety scanner can flag. Never shown as a diagnosis of the
/// other person — only used to route to a calm, non-escalating response.
enum RiskFlag: String, Codable, CaseIterable, Hashable {
    case violenceThreat
    case selfHarm
    case coercion
    case stalking
    case sexualExploitation
    case abuseIndicator
}

/// The AI's suggested next step, distinct from `verdict` — lets the UI pick
/// a more specific action label (e.g. "direct" nudges toward a more direct
/// rewrite rather than a generic one). Only ever set by
/// `RemoteAIJudgmentProvider`; deterministic/local results leave it `nil`.
enum RecommendedAction: String, Codable, Hashable {
    case send
    case wait
    case rewrite
    case direct
}

/// The structured result of judging a single message. This is the local
/// equivalent of the JSON contract described in API_CONTRACT.md so the
/// engine can be swapped for a remote service later without touching the
/// UI layer.
struct JudgmentResult: Codable, Equatable {
    let verdict: Verdict
    let reason: String
    let riskFlags: [RiskFlag]
    let isSafetyRouted: Bool
    /// Set only by a genuine semantic (AI) judgment — see `RecommendedAction`.
    let recommendedAction: RecommendedAction?
    /// Contextual rewrite suggestions from the AI, if any. Empty for every
    /// deterministic/local result — `JudgeViewModel.startRewrite()` falls
    /// back to `RewriteEngine`'s fixed templates when this is empty.
    let rewriteOptions: [RewriteOption]
    /// True only when this result came from the on-device conservative
    /// fallback because the AI judgment service was unavailable (offline,
    /// timeout, or invalid response) — never true for a genuine AI
    /// judgment or for safety/mechanical routing. Drives the "judged
    /// locally, limited" banner in `VerdictView`. See `AI_SAFETY.md` and
    /// `DECISIONS.md`.
    let isLocalFallback: Bool

    init(
        verdict: Verdict,
        reason: String,
        riskFlags: [RiskFlag] = [],
        isSafetyRouted: Bool = false,
        recommendedAction: RecommendedAction? = nil,
        rewriteOptions: [RewriteOption] = [],
        isLocalFallback: Bool = false
    ) {
        self.verdict = verdict
        self.reason = reason
        self.riskFlags = riskFlags
        self.isSafetyRouted = isSafetyRouted
        self.recommendedAction = recommendedAction
        self.rewriteOptions = rewriteOptions
        self.isLocalFallback = isLocalFallback
    }

    var hasRisk: Bool { !riskFlags.isEmpty }
}

/// A single rewrite suggestion.
struct RewriteOption: Codable, Equatable, Identifiable {
    let id: UUID
    let text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}
