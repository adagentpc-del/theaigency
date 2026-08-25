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

/// The structured result of judging a single message. This is the local
/// equivalent of the JSON contract described in API_CONTRACT.md so the
/// engine can be swapped for a remote service later without touching the
/// UI layer.
struct JudgmentResult: Codable, Equatable {
    let verdict: Verdict
    let reason: String
    let riskFlags: [RiskFlag]
    let isSafetyRouted: Bool

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
