import Foundation

/// Everything a `JudgmentProvider` needs to produce a verdict. Assembled
/// once, after all three input steps are complete — judgment never runs
/// on the proposed message alone. See `API_CONTRACT.md` for the wire
/// shape this maps to if a remote provider is introduced later.
struct JudgmentRequest: Codable, Equatable, Hashable {
    let proposedMessage: String
    let goal: Goal
    let context: ContextInput
}
