import Foundation

/// Step 3 offers two ways to describe what happened before the proposed
/// message — the user picks exactly one.
enum ContextInput: Codable, Equatable, Hashable {
    /// Option A — the user pastes the recent, relevant part of the
    /// conversation. Stays on-device like everything else; see
    /// `PRIVACY_DATA_MAP.md`. The local judgment provider deliberately
    /// does NOT attempt deep understanding of this free text (see
    /// `ContextSignals` and `DECISIONS.md`) — that's the job reserved for
    /// a future `RemoteAIJudgmentProvider`.
    case conversation(String)
    /// Option B — a few closed-choice questions the local engine can
    /// reason about reliably.
    case quick(QuickContext)
}
