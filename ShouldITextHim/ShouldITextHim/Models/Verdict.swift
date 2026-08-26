import Foundation

/// The five possible outcomes of judging a message. `needContext` is a
/// deliberate, first-class answer — not an error state — for when the
/// model doesn't have enough information to responsibly judge tone, goal
/// fit, or context. See `AI_SAFETY.md` — absence of a detected problem is
/// never evidence for `.send`; when there isn't enough evidence either
/// way, the honest answer is to ask for more, not to guess.
enum Verdict: String, Codable, CaseIterable, Hashable {
    case send
    case rewrite
    case sleep
    case dontSend
    case needContext

    var headline: String {
        switch self {
        case .send: return "SEND IT."
        case .rewrite: return "REWRITE IT."
        case .sleep: return "SLEEP ON IT."
        case .dontSend: return "DON'T SEND IT."
        case .needContext: return "NEED MORE CONTEXT."
        }
    }

    /// VoiceOver-friendly phrasing (avoids relying on all-caps punctuation for tone).
    var accessibilityLabel: String {
        switch self {
        case .send: return "Verdict: Send it."
        case .rewrite: return "Verdict: Rewrite it."
        case .sleep: return "Verdict: Sleep on it."
        case .dontSend: return "Verdict: Don't send it."
        case .needContext: return "Verdict: I need more context to judge this."
        }
    }

    /// Distinct symbol per verdict so meaning is never color-only.
    var symbolName: String {
        switch self {
        case .send: return "paperplane.fill"
        case .rewrite: return "pencil.line"
        case .sleep: return "moon.zzz.fill"
        case .dontSend: return "hand.raised.fill"
        case .needContext: return "questionmark.circle.fill"
        }
    }
}
