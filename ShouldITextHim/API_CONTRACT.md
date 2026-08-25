# API Contract — Judgment Provider

This release ships with **no network API** — `LocalJudgmentProvider` computes everything on-device (see `DECISIONS.md` for why). This document describes the actual abstraction now in the codebase (`JudgmentProvider`) and how a future remote/AI-backed provider would plug into it, so that work can happen deliberately later without touching the UI layer.

## The interface (already in the codebase today)

```swift
protocol JudgmentProvider: Sendable {
    func judge(_ request: JudgmentRequest) async -> JudgmentResult
}
```

`JudgeViewModel` is initialized with a `JudgmentProvider` (defaulting to `LocalJudgmentProvider()`) and never references a concrete implementation directly. Swapping in a different provider is a one-line change to `JudgeViewModel.init`'s default argument.

### Request shape

```swift
struct JudgmentRequest {
    let proposedMessage: String
    let goal: Goal                  // .flirt, .makePlans, .getClarity, .apologize,
                                     // .setBoundary, .getClosure, .checkingIn
    let context: ContextInput       // .conversation(String) OR .quick(QuickContext)
}

struct QuickContext {
    var whoTextedLast: WhoTextedLast          // .me, .him, .notSure
    var timeSinceLastMessage: TimeSinceLastMessage  // .underAnHour, .today, .oneToThreeDays, .fourPlusDays
    var didHeRespond: DidHeRespond            // .yes, .no, .sortOf, .noQuestion
    var additionalNotes: String
}
```

### Response shape

```swift
struct JudgmentResult {
    let verdict: Verdict            // .send, .rewrite, .sleep, .dontSend
    let reason: String              // short, one to two sentences, must reference goal/context
    let riskFlags: [RiskFlag]
    let isSafetyRouted: Bool
}
```

This is the exact Swift shape today; a JSON wire format for a remote provider would mirror it directly (`Goal`, `Verdict`, `RiskFlag`, `WhoTextedLast`, etc. are all `Codable` with stable `rawValue`s specifically so this translation is mechanical).

## How the local provider is composed (for context on what a remote one replaces)

`LocalJudgmentProvider.judge(_:)` runs three layers in order — see `DECISIONS.md` decision 7 for the full rationale:

1. `SafetyScanner.scan(_:)` over all free text in the request (proposed message + pasted conversation or quick-context notes) — always first, always wins.
2. `DeterministicJudgmentRules.evaluate(goal:message:context:)` — an ordered, explainable rule list combining goal, message tone (`MessageSignals`), and context signals (`ContextSignals`). Returns `nil` when no rule confidently applies.
3. `FallbackJudgment.decide(goal:message:context:)` — a conservative, still context-aware default used only when layer 2 returns `nil`.

## If/when a remote provider replaces (or supplements) the local one

1. **Add `RemoteAIJudgmentProvider: JudgmentProvider`** conforming to the exact same protocol. The natural design keeps `LocalJudgmentProvider`'s safety layer (step 1 above) running **before** any network call, even inside `RemoteAIJudgmentProvider` — never send text to a remote model before the local safety check has had a chance to short-circuit. This keeps the highest-risk category of message from ever leaving the device at all, and means safety routing stays deterministic and instant even after a network provider exists (see `AI_SAFETY.md`).
2. **Never place the backend's API key in the client.** The client calls theAIgincy's own server-side proxy; the proxy holds the model-provider credential. This mirrors the Day 1 spec's non-negotiable requirement.
3. **Send the minimum necessary data** — the proposed message, the goal, and whichever context the user provided. No device identifiers, no user identifiers (there are none to send).
4. **Do not persist or log raw user content server-side**, including the pasted conversation and quick-context notes — the proxy should treat all of it as pass-through only.
5. **Bound and validate the output.** Decode the response directly into `JudgmentResult`/`Verdict`/`RiskFlag` and fail closed (fall back to a safe local default, e.g. treat a decode failure or timeout as `.rewrite` with a "we couldn't judge that, try rephrasing" reason) rather than rendering an unrecognized value. This is exactly the discipline `DeterministicJudgmentRules` already follows by returning `nil` instead of guessing.
6. **Timeouts and retry:** a short request timeout (e.g. 8–10s) with a single retry on transient network failure, then an explicit error state — never an infinite spinner.
7. **Where the pasted-conversation path actually benefits:** the local provider deliberately does not deep-parse pasted conversations today (`DECISIONS.md` decision 9) — that's precisely the case a remote provider with real language understanding would improve most, since quick-context answers already get solid deterministic reasoning locally. A reasonable rollout is remote judgment for the `.conversation` context case only, keeping `.quick` context local-only (fast, private, free) unless/until there's a reason to change that.
8. **Update `PRIVACY_DATA_MAP.md`, `PrivacyInfo.xcprivacy`, and the App Store Privacy questionnaire** the same day network calls are introduced — this document existing does not pre-authorize skipping that step.

## Why this isn't built yet

Building a real server-side proxy requires hosting, a domain, billing, and a business decision about ongoing operating cost — outside what a from-scratch repo in this environment can responsibly stand up. See `DECISIONS.md` and `FOUNDER_ACTION_REQUIRED.md`.
