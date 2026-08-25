import Foundation

/// Abstraction over "turn a judgment request into a verdict." Everything
/// above this layer (the ViewModel, every View) depends only on this
/// protocol, never on `LocalJudgmentProvider` directly — so a future
/// `RemoteAIJudgmentProvider` (backed by theAIgincy's own server-side
/// proxy, never an API key in the client — see `API_CONTRACT.md`) can be
/// swapped in later by changing one line of dependency injection.
protocol JudgmentProvider: Sendable {
    func judge(_ request: JudgmentRequest) async -> JudgmentResult
}
