import Foundation

/// Deterministic, on-device safety scan. Looks for language patterns that
/// indicate the drafted message itself carries real-world risk (to the
/// user or to someone else) and routes those cases away from the normal
/// witty verdict flow into a calm, non-escalating response.
///
/// This is intentionally a small, auditable pattern list rather than a
/// general moderation platform — see AI_SAFETY.md for the full rule set
/// and rationale, and POST_LAUNCH.md for why a full ML classifier is out
/// of scope for this release.
enum SafetyScanner {

    private struct Pattern {
        let flag: RiskFlag
        let terms: [String]
    }

    /// Lowercase, word-boundary-ish substring matches. Deliberately biased
    /// toward catching real risk over precision: a false positive costs the
    /// user a calmer-than-necessary response, a false negative could ship
    /// something dangerous.
    private static let patterns: [Pattern] = [
        Pattern(flag: .violenceThreat, terms: [
            "i'll kill you", "i will kill you", "i'm going to kill you",
            "i'll hurt you", "i will hurt you", "i'm going to hurt you",
            "you'll pay for this", "you will pay for this",
            "watch your back", "i'll beat you", "i will beat you",
            "i'm going to make you pay", "i own a gun and", "bring a knife"
        ]),
        Pattern(flag: .selfHarm, terms: [
            "kill myself", "end my life", "want to die", "better off dead",
            "no reason to live", "i'll hurt myself", "i will hurt myself",
            "going to end it", "can't go on living", "suicide"
        ]),
        Pattern(flag: .coercion, terms: [
            "if you don't reply i'll", "if you don't answer i'll",
            "if you don't text back i'll", "you owe me", "you have to or else",
            "i'll tell everyone if you don't", "do it or i'll",
            "send it or i'll", "you better respond or"
        ]),
        Pattern(flag: .stalking, terms: [
            "i know where you live", "i'll be outside your", "i will be outside your",
            "i saw you with", "i'm watching you", "i am watching you",
            "i followed you", "i'm outside your house", "i am outside your house",
            "i won't stop texting", "i will not stop texting", "i'm not going to stop until",
            "i'll find you", "i will find you", "i know your schedule"
        ]),
        Pattern(flag: .sexualExploitation, terms: [
            "send nudes or", "i'll post your pictures", "i will post your pictures",
            "i'll leak", "i will leak", "send a pic or i'll", "share your photos unless",
            "i'll send your pics to"
        ]),
        Pattern(flag: .abuseIndicator, terms: [
            "you're nothing without me", "you are nothing without me",
            "no one else will ever want you", "you'll never find anyone like me",
            "you will never find anyone like me", "i'll ruin your life",
            "i will ruin your life", "you're worthless", "you are worthless"
        ])
    ]

    /// Returns every risk category the text matches. Empty when clean.
    static func scan(_ text: String) -> [RiskFlag] {
        let normalized = text.lowercased()
        var found: Set<RiskFlag> = []
        for pattern in patterns {
            for term in pattern.terms where normalized.contains(term) {
                found.insert(pattern.flag)
                break
            }
        }
        return Array(found).sorted { $0.rawValue < $1.rawValue }
    }

    /// Calm, non-escalating copy shown when a message is safety-routed.
    /// Never jokes, never diagnoses, never tells the user what to feel.
    static func safeResponse(for flags: [RiskFlag]) -> JudgmentResult {
        JudgmentResult(
            verdict: .dontSend,
            reason: "This message includes language that could seriously harm you or someone else. We're not going to joke about this one — please don't send it as written, and consider talking to someone you trust.",
            riskFlags: flags,
            isSafetyRouted: true
        )
    }
}
