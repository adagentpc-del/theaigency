import Foundation

/// The four possible outcomes of judging a message.
enum Verdict: String, Codable, CaseIterable, Hashable {
    case send
    case rewrite
    case sleep
    case dontSend

    var headline: String {
        switch self {
        case .send: return "SEND IT."
        case .rewrite: return "REWRITE IT."
        case .sleep: return "SLEEP ON IT."
        case .dontSend: return "DON'T SEND IT."
        }
    }

    /// VoiceOver-friendly phrasing (avoids relying on all-caps punctuation for tone).
    var accessibilityLabel: String {
        switch self {
        case .send: return "Verdict: Send it."
        case .rewrite: return "Verdict: Rewrite it."
        case .sleep: return "Verdict: Sleep on it."
        case .dontSend: return "Verdict: Don't send it."
        }
    }

    /// Distinct symbol per verdict so meaning is never color-only.
    var symbolName: String {
        switch self {
        case .send: return "paperplane.fill"
        case .rewrite: return "pencil.line"
        case .sleep: return "moon.zzz.fill"
        case .dontSend: return "hand.raised.fill"
        }
    }
}
