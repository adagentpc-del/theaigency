import Foundation

/// Everything a `JudgmentProvider` needs to produce a verdict. Assembled
/// once, after all three input steps are complete — judgment never runs
/// on the proposed message alone. This is also, verbatim, the JSON body
/// `RemoteAIJudgmentProvider` posts to the server proxy — see
/// `API_CONTRACT.md` for the wire contract.
struct JudgmentRequest: Codable, Equatable, Hashable {
    let proposedMessage: String
    let goal: Goal
    let context: ContextInput

    /// Every piece of free text the user entered, joined together. Used so
    /// the safety scan can never be bypassed by putting risky language in
    /// a context field instead of the proposed message.
    var combinedFreeText: String {
        var parts = [proposedMessage]
        switch context {
        case .conversation(let text):
            parts.append(text)
        case .quick(let quick):
            parts.append(quick.additionalNotes)
        }
        return parts.joined(separator: "\n")
    }
}
