# API Contract — Judgment Engine

This release ships with **no network API** — `Engine/JudgmentEngine.swift` computes everything on-device (see `DECISIONS.md` for why). This document exists so that a future remote/AI-backed engine can be swapped in without changing the UI layer, and so the contract is decided deliberately rather than improvised later.

## Contract shape (already true of the local engine today)

```
struct JudgmentResult {
    verdict: "send" | "rewrite" | "sleep" | "dont_send"
    reason: String            // short, one to two sentences
    riskFlags: [String]       // subset of the six AI_SAFETY.md categories
    isSafetyRouted: Bool
}
```

Swift-side this is exactly `Models/JudgmentResult.swift` today (`Verdict`/`RiskFlag` enums instead of raw strings — a hypothetical JSON wire format would use their `rawValue`s).

Rewrite options:

```
struct RewriteOption {
    text: String
}
// RewriteEngine.options(for: Intent) -> [RewriteOption], up to 3
```

## If/when a remote engine replaces the local one

1. **Define a `JudgmentEngineProviding` protocol** with `func judge(_ text: String) async throws -> JudgmentResult`, and make the existing local logic one conforming implementation (`LocalJudgmentEngine`) alongside a new `RemoteJudgmentEngine`. `JudgeViewModel` should depend on the protocol, not a concrete type, exactly the way it already depends on `ClipboardWriting` rather than `UIPasteboard` directly.
2. **Never place the backend's API key in the client.** The client calls theAIgincy's own server-side proxy; the proxy holds the model-provider credential. This mirrors the Day 1 spec's non-negotiable requirement.
3. **Send the minimum necessary text** — just the pasted message and, for rewrites, the selected intent. No device identifiers, no user identifiers (there are none to send).
4. **Do not persist or log raw user messages server-side.** The proxy should treat the message as pass-through only.
5. **Bound the output.** Short, fixed-shape JSON only — no free-form long-form generation. Validate the decoded `verdict` against the closed `Verdict` enum and fail closed (fall back to a safe local default, e.g. treat decode failure as `.rewrite` with a "we couldn't judge that, try rephrasing" reason) rather than rendering an unrecognized value.
6. **Timeouts and retry:** a short request timeout (e.g. 8–10s) with a single retry on transient network failure, then fall back to an explicit error state — never an infinite spinner. See `PRODUCT_SPEC.md`'s error-state requirements for the loading screen.
7. **Safety routing stays local-first.** Run `SafetyScanner` against the raw text *before* any network call, exactly as today — never send text to a remote model before the local safety check has had a chance to short-circuit, since that keeps the highest-risk category of message from ever leaving the device at all.
8. **Update `PRIVACY_DATA_MAP.md`, `PrivacyInfo.xcprivacy`, and the App Store Privacy questionnaire** the same day network calls are introduced — this document existing does not pre-authorize skipping that step.

## Why this isn't built yet

Building a real server-side proxy requires hosting, a domain, billing, and a business decision about ongoing operating cost for a Day 1 experiment — all outside what a from-scratch repo in this environment can responsibly stand up. See `DECISIONS.md` and `FOUNDER_ACTION_REQUIRED.md`.
