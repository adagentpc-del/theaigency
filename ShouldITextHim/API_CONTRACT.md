# API Contract — Judgment Provider

This describes the `JudgmentProvider` abstraction, the wire contract `RemoteAIJudgmentProvider` uses to talk to theAIgincy's server-side proxy, and how the two are composed. **The server-side proxy now exists** (`server/`) — see `server/README.md` for deployment. No model-provider API key is ever compiled into the iOS app; the proxy holds it.

## The interface

```swift
protocol JudgmentProvider: Sendable {
    func judge(_ request: JudgmentRequest) async -> JudgmentResult
}
```

`JudgeViewModel` depends only on this protocol (default: `RemoteAIJudgmentProvider()`), never on a concrete implementation. Two conformances exist today:

- **`RemoteAIJudgmentProvider`** — the app's primary provider. Runs local safety/mechanical pre-filters first, then calls the server for genuine semantic judgment; falls back to `LocalJudgmentProvider`'s conservative result on any failure.
- **`LocalJudgmentProvider`** — fully on-device (safety + mechanical rules + conservative fallback). Used inside `RemoteAIJudgmentProvider` as the pre-filter/fallback layer, and directly in tests. **Can never return `.send`** — see `AI_SAFETY.md`.

### Request shape

```swift
struct JudgmentRequest: Codable {
    let proposedMessage: String
    let goal: Goal                  // .flirt, .makePlans, .getClarity, .apologize,
                                     // .setBoundary, .getClosure, .checkingIn
    let context: ContextInput       // .conversation(String) OR .quick(QuickContext)
}

struct QuickContext: Codable {
    var whoTextedLast: WhoTextedLast          // .me, .him, .notSure
    var timeSinceLastMessage: TimeSinceLastMessage  // .underAnHour, .today, .oneToThreeDays, .fourPlusDays
    var didHeRespond: DidHeRespond            // .yes, .no, .sortOf, .noQuestion
    var additionalNotes: String
}
```

`JudgmentRequest` is `Codable`, and `RemoteAIJudgmentProvider` posts it directly as the request body via `JSONEncoder`. Swift's SE-0295 synthesis encodes the `ContextInput` enum as a single-key object keyed by case name — e.g. `{"context": {"quick": {...}}}` or `{"context": {"conversation": "..."}}`. `server/lib/schema.ts`'s Zod schema is hand-written to match this exactly; there is no shared code generation, so **keep the two in lockstep by hand** if either side's model changes.

### Response shape (server → client)

```json
{
  "verdict": "send" | "rewrite" | "sleep" | "dont_send",
  "reason": "one or two plain sentences",
  "recommended_action": "send" | "wait" | "rewrite" | "direct",
  "rewrite_options": ["...", "...", "..."]
}
```

The client decodes this into a private `RemoteJudgmentResponseDTO`, validates every field strictly, and only then constructs a `JudgmentResult`:

```swift
struct JudgmentResult {
    let verdict: Verdict
    let reason: String
    let riskFlags: [RiskFlag]
    let isSafetyRouted: Bool
    let recommendedAction: RecommendedAction?   // drives a small UI label change
    let rewriteOptions: [RewriteOption]          // AI-provided; empty for local/deterministic results
    let isLocalFallback: Bool                    // true only when the AI was unavailable
}
```

Validation rules (`RemoteJudgmentResponseDTO.validated()` in `RemoteAIJudgmentProvider.swift`):
- `verdict` must map to a known `Verdict` case (note the wire value is `dont_send`, snake_case, mapped to Swift's `.dontSend`) — anything else fails validation.
- `reason` must be non-empty and ≤600 characters.
- `rewrite_options` entries are trimmed, empty ones dropped, each capped at 500 characters, and the whole list capped at 3.
- `recommended_action` is best-effort — an unrecognized value just leaves `recommendedAction` `nil` rather than failing the whole response (it only drives a minor UI label, not the verdict itself).

Any validation failure, non-200 HTTP status, or network error/timeout is treated identically: fall back to `LocalJudgmentProvider`'s conservative result, mark `isLocalFallback = true`, never render an unvalidated payload.

## How `RemoteAIJudgmentProvider` is composed

1. `SafetyScanner.scan(request.combinedFreeText)` — always first, always local, always wins. A safety-routed message never reaches the network.
2. `DeterministicJudgmentRules.evaluate(...)` — mechanical facts (repeated contact, double-texting, breakup topic, message length, long silence, unanswered direct question). Always local. Never returns `.send`.
3. If neither of the above resolves it: `POST` to the server proxy for genuine semantic judgment.
4. If step 3 fails for any reason: `FallbackJudgment.decide(...)` — always local, always conservative, never `.send`.

See `AI_SAFETY.md` for the full rationale, and `RemoteAIJudgmentProvider.swift` for the implementation.

## The server-side proxy

Lives in `server/` — a minimal TypeScript serverless function (`server/api/judge.ts`), designed for Vercel but portable to any Node-compatible serverless platform. See `server/README.md` for deployment/configuration. Summary of what it does and doesn't do:

- Validates the incoming request strictly (Zod, `server/lib/schema.ts`) before it ever reaches the model.
- Calls the Claude API (`claude-opus-5`) with a fixed system prompt (`server/lib/prompt.ts`) and structured-output validation (`output_config.format`), so the model's response is schema-constrained.
- Re-validates the model's output server-side too (belt-and-suspenders on top of the client's own validation).
- **Never logs request or response content** — only an error type/name on failure.
- **Never persists anything** — stateless function, no database.
- Holds the Anthropic API key as a server-side environment variable; the client only ever knows the proxy's public URL (`RemoteAIJudgmentProvider.defaultEndpoint` — currently a placeholder, see `FOUNDER_ACTION_REQUIRED.md`).
- Has **no per-caller rate limiting or request authentication** yet beyond a payload-size cap — a documented, accepted risk for this stage; see `server/README.md` → "Known limitation: abuse mitigation" and `POST_LAUNCH.md`.

## Testing the contract

- `RemoteAIJudgmentProviderTests.swift` + `MockURLProtocol.swift` — exercises the full client-side contract (decode, validation, error handling, local pre-filter short-circuits) against a scripted mock, with zero real network calls or API keys.
- `AdversarialSemanticFixtureTests.swift` — proves the same plumbing correctly surfaces a scripted "ideal" verdict for a representative set of adversarial fixtures.
- `RemoteAIJudgmentProviderLiveTests.swift` — the only test that can validate actual model judgment quality; runs all 60 adversarial fixtures against a real deployed endpoint when `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` is set, otherwise skips.

## Future extension: deeper pasted-conversation understanding

The local pre-filter layer deliberately does not deep-parse a pasted conversation's history — see `DECISIONS.md` decision 9. Since semantic judgment is now live for the proposed-message/goal/context triple, a natural next step (not built yet) is having the server prompt reason more deeply over a long pasted conversation's structure (who said what, how the tone shifted) rather than treating it as one opaque block of context text. Tracked in `POST_LAUNCH.md`.
