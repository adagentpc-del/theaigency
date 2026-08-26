# API Contract — Judgment Provider

This describes the `JudgmentProvider` abstraction, the wire contract `RemoteAIJudgmentProvider` uses to talk to theAIgincy's application API, and how the two are composed. **The application API now exists** (`server/`) — see `server/README.md` for deployment. The iOS app never talks to a model or an inference server directly, and never holds any hosted-AI-provider or local-inference credential — it only knows this API's public `/api/judge` URL, which in turn talks privately to a **self-hosted local language model**.

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
  "verdict": "send" | "rewrite" | "sleep" | "dont_send" | "need_context",
  "reason": "one or two plain sentences",
  "recommended_action": "send" | "wait" | "rewrite" | "direct" | "add_context",
  "rewrite_options": ["...", "...", "..."]
}
```

`need_context` / `add_context` is a first-class, deliberate answer for when the model doesn't have enough information to responsibly judge tone, goal fit, or context consistency — see `AI_SAFETY.md` → "The NEED MORE CONTEXT verdict." It is not an error state and is always returned with an empty `rewrite_options` array.

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
- `verdict` must map to a known `Verdict` case (note the wire values are snake_case — `dont_send` → `.dontSend`, `need_context` → `.needContext`) — anything else fails validation.
- `reason` must be non-empty and ≤600 characters.
- `rewrite_options` entries are trimmed, empty ones dropped, each capped at 500 characters, and the whole list capped at 3.
- `recommended_action` is best-effort — an unrecognized value just leaves `recommendedAction` `nil` rather than failing the whole response (it only drives a minor UI label, not the verdict itself). Note `add_context`'s wire value uses an explicit snake_case raw value (`RecommendedAction.addContext = "add_context"`) since Swift's default synthesis would otherwise expect `addContext`.

Any validation failure, non-200 HTTP status, or network error/timeout is treated identically: fall back to `LocalJudgmentProvider`'s conservative result, mark `isLocalFallback = true`, never render an unvalidated payload.

## How `RemoteAIJudgmentProvider` is composed

1. `SafetyScanner.scan(request.combinedFreeText)` — always first, always local, always wins. A safety-routed message never reaches the network.
2. `DeterministicJudgmentRules.evaluate(...)` — mechanical facts (repeated contact, double-texting, breakup topic, message length, long silence, unanswered direct question). Always local. Never returns `.send`.
3. If neither of the above resolves it: `POST` to the server proxy for genuine semantic judgment.
4. If step 3 fails for any reason: `FallbackJudgment.decide(...)` — always local, always conservative, never `.send`.

See `AI_SAFETY.md` for the full rationale, and `RemoteAIJudgmentProvider.swift` for the implementation.

## The application API

Lives in `server/` — a small, persistent Node/Express service (not a serverless function), designed to sit in front of a self-hosted local inference server (llama.cpp server or Ollama). See `server/README.md` for the full architecture diagram and deployment/configuration. Summary of what it does and doesn't do:

- Validates the incoming request strictly (Zod, `server/src/lib/schema.ts`) and rate-limits the caller before it ever reaches the model.
- Calls the configured local model (`LOCAL_LLM_BASE_URL` / `LOCAL_LLM_MODEL`, never hard-coded — `server/src/lib/localInferenceClient.ts`) over an OpenAI-compatible `/v1/chat/completions` request, with a fixed system prompt (`server/src/lib/prompt.ts`) and, where the inference server supports it, constrained/schema-guided JSON output.
- Re-validates the model's output server-side too (belt-and-suspenders on top of the client's own validation) — malformed JSON or an out-of-schema value is rejected, never passed through.
- **Never logs request or response content** — only an error type/name on failure.
- **Never persists anything** — no database, nothing written to disk between requests.
- Holds **no third-party hosted-AI API key at all** — there is no such credential anywhere in this project. The client only ever knows this API's public URL (`RemoteAIJudgmentProvider.defaultEndpoint` — currently a placeholder, see `FOUNDER_ACTION_REQUIRED.md`), which in turn talks privately to the self-hosted inference server.
- Has basic, single-instance, IP-based rate limiting and a payload-size cap — see `server/README.md` → "Security" and "Known limitations."

## Testing the contract

- `RemoteAIJudgmentProviderTests.swift` + `MockURLProtocol.swift` — exercises the full client-side contract (decode, validation including `need_context`/`add_context`, error handling, local pre-filter short-circuits) against a scripted mock, with zero real network calls or API keys.
- `AdversarialSemanticFixtureTests.swift` — proves the same plumbing correctly surfaces a scripted "ideal" verdict for a representative set of adversarial fixtures.
- `RemoteAIJudgmentProviderLiveTests.swift` — the only client-side test that can validate actual model judgment quality; runs all 60 adversarial fixtures against a real deployed endpoint when `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` is set, otherwise skips.
- `server/scripts/benchmark.ts` — runs the same 60 fixtures directly against a configured local model, independent of the iOS app entirely, and is the tool used to decide which model is actually good enough to deploy. See `server/README.md` → "Model benchmark harness."

## Future extension: deeper pasted-conversation understanding

The local pre-filter layer deliberately does not deep-parse a pasted conversation's history — see `DECISIONS.md` decision 9. Since semantic judgment is now live for the proposed-message/goal/context triple, a natural next step (not built yet) is having the server prompt reason more deeply over a long pasted conversation's structure (who said what, how the tone shifted) rather than treating it as one opaque block of context text. Tracked in `POST_LAUNCH.md`.
