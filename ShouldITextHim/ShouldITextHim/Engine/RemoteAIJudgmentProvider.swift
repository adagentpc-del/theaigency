import Foundation

/// The semantic `JudgmentProvider` — the app's primary judgment path in
/// production. Runs the same local safety and mechanical pre-filters as
/// `LocalJudgmentProvider` first (fast, free, and safety-critical
/// regardless of network availability — see `AI_SAFETY.md`), then calls
/// theAIgincy's own server-side proxy for genuine semantic judgment of
/// anything those filters don't confidently resolve: hostility, sarcasm,
/// passive aggression, manipulation, guilt-tripping, veiled threats, and
/// the rest of the "Product Behavior" list in `AI_SAFETY.md`.
///
/// No API key for the model provider is ever compiled into this app —
/// the proxy holds it server-side. See `API_CONTRACT.md` for the full
/// contract and `server/README.md` for how the proxy itself is deployed.
struct RemoteAIJudgmentProvider: JudgmentProvider {
    /// Public, non-secret endpoint — safe to embed in the client, since it
    /// is a URL, not a credential. **Placeholder** until the proxy is
    /// actually deployed — see FOUNDER_ACTION_REQUIRED.md.
    static let defaultEndpoint = URL(string: "https://should-i-text-him.example.com/api/judge")!

    private let endpoint: URL
    private let urlSession: URLSession
    private let requestTimeout: TimeInterval

    init(
        endpoint: URL = RemoteAIJudgmentProvider.defaultEndpoint,
        urlSession: URLSession = .shared,
        requestTimeout: TimeInterval = 10
    ) {
        self.endpoint = endpoint
        self.urlSession = urlSession
        self.requestTimeout = requestTimeout
    }

    func judge(_ request: JudgmentRequest) async -> JudgmentResult {
        // Safety and mechanical rules always run locally first, regardless
        // of network availability — see DeterministicJudgmentRules for why
        // these never return SEND IT.
        let riskFlags = SafetyScanner.scan(request.combinedFreeText)
        if !riskFlags.isEmpty {
            return SafetyScanner.safeResponse(for: riskFlags)
        }

        let message = MessageSignals(text: request.proposedMessage)
        let context = ContextSignals(context: request.context)

        if let mechanicalResult = DeterministicJudgmentRules.evaluate(goal: request.goal, message: message, context: context) {
            return mechanicalResult
        }

        // Everything else — including plain hostility/profanity that
        // doesn't match any keyword list — goes to genuine semantic
        // judgment. If that fails for any reason, fall back to a
        // conservative, clearly-labeled local result rather than faking
        // confidence. Never SEND IT from this path either.
        do {
            return try await fetchRemoteJudgment(for: request)
        } catch {
            return FallbackJudgment.decide(goal: request.goal, message: message, context: context)
        }
    }

    private func fetchRemoteJudgment(for request: JudgmentRequest) async throws -> JudgmentResult {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = requestTimeout
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await urlSession.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw RemoteJudgmentError.badResponse
        }

        let decoded = try JSONDecoder().decode(RemoteJudgmentResponseDTO.self, from: data)
        return try decoded.validated()
    }
}

private enum RemoteJudgmentError: Error {
    case badResponse
    case invalidPayload
}

/// Mirrors the server's JSON response exactly (see `API_CONTRACT.md`).
/// Kept separate from `JudgmentResult` so every field is strictly
/// validated before anything reaches the UI — a malformed, missing, or
/// out-of-range field is treated as a failure (triggering the local
/// fallback), never rendered as-is. This is the "validate the response
/// before rendering" requirement.
private struct RemoteJudgmentResponseDTO: Decodable {
    let verdict: String
    let reason: String
    let recommended_action: String
    let rewrite_options: [String]

    func validated() throws -> JudgmentResult {
        guard let verdict = Verdict(wireValue: verdict) else {
            throw RemoteJudgmentError.invalidPayload
        }
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty, trimmedReason.count <= 600 else {
            throw RemoteJudgmentError.invalidPayload
        }
        let recommendedAction = RecommendedAction(rawValue: recommended_action)
        let options = rewrite_options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count <= 500 }
            .prefix(3)
            .map { RewriteOption(text: $0) }

        return JudgmentResult(
            verdict: verdict,
            reason: trimmedReason,
            recommendedAction: recommendedAction,
            rewriteOptions: Array(options),
            isLocalFallback: false
        )
    }
}

private extension Verdict {
    /// The wire contract uses `dont_send` (snake_case), not Swift's
    /// `dontSend` raw value.
    init?(wireValue: String) {
        switch wireValue {
        case "send": self = .send
        case "rewrite": self = .rewrite
        case "sleep": self = .sleep
        case "dont_send": self = .dontSend
        default: return nil
        }
    }
}
