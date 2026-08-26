# AI Safety — Should I Text Him?

This document is the full rule set governing how the app judges messages and handles potentially high-risk content and repeated/unwanted-contact patterns. Three QA passes on physical devices found real defects here; this revision describes the architecture that fixes all three.

## History: three defects, three fixes

1. **First defect**: the original engine judged the pasted message in isolation, with no knowledge of the user's goal or what had happened before it, and defaulted to SEND IT far too often. **Fix**: judgment became a 3-step flow (message, goal, context) and the engine started reasoning about goal+context together (`DeterministicJudgmentRules`, `ContextSignals`).
2. **Second defect**: even with goal and context, a purely keyword-based engine still couldn't recognize hostility, sarcasm, passive aggression, manipulation, or profanity outside a fixed phrase list — `"hello gangster what the fuck is your problem"` still returned SEND IT, because it matched no keyword. **Fix**: primary judgment became genuinely semantic, via `RemoteAIJudgmentProvider` calling a real AI model through theAIgincy's own application API.
3. **Third revision** (architecture change, not a new judgment-quality defect): the backend that provides semantic judgment moved from a hosted third-party AI provider to a **self-hosted local language model** running on theAIgincy's own infrastructure. Product behavior, safety routing, and the never-SEND-IT invariant below are all unchanged — only where the model runs and who operates it changed. See `DECISIONS.md` decision 18 for the full rationale, and the new `need_context` verdict added at the same time (below).

The deterministic engine's role stayed "the safety net and the offline fallback," never "the judge," across all three revisions — see `DECISIONS.md` for the full architectural history.

## Three mechanisms, in priority order

1. **Safety routing** (`SafetyScanner`) — catches high-risk *language* (threats, self-harm statements, coercive or stalking phrasing, sexual exploitation, abusive control language) regardless of goal, context, or network availability, and always wins. Runs first, entirely on-device, for every single request.
2. **Repeated-contact guarding** (`DeterministicJudgmentRules`, rule 1) — catches a self-reported *pattern* (already texted/called more than once without a response), even when the proposed message itself is polite. Runs second, entirely on-device.
3. **Semantic judgment** (`RemoteAIJudgmentProvider`) — for everything mechanisms 1 and 2 don't resolve, a real AI model reads the actual message, goal, and context and judges whether sending it is advisable. This is now the **primary** path for the app's core "is this OK to send" question — see `API_CONTRACT.md` for the exact contract and `server/src/lib/prompt.ts` for what the model is instructed to do. The model itself is **self-hosted**: theAIgincy's own application API (`server/`) calls a local inference server (llama.cpp server or Ollama) running a small open-weight model on theAIgincy's own infrastructure — never a third-party hosted-AI API. See "Mechanism 3" below and the architecture diagram in `server/README.md`.

A few purely mechanical facts (a message over 120 words, explicit breakup-topic phrases, having just texted moments ago, a long silence with no positive signal, an unanswered direct question) are still resolved locally too (`DeterministicJudgmentRules`, rules 3–6) — not because tone matters less, but because these are structural facts a network call adds no value in confirming, and resolving them locally is faster and free. **None of these mechanical rules, and no local rule anywhere in this app, is ever allowed to return SEND IT** — see "The SEND IT invariant" below.

## Mechanism 1: Safety routing

Unchanged from the first release. `SafetyScanner` performs a deterministic, on-device, case-insensitive substring scan against six categories (`RiskFlag`): `violenceThreat`, `selfHarm`, `coercion`, `stalking`, `sexualExploitation`, `abuseIndicator`. The scan covers **every piece of free text the user can enter** — the proposed message, the pasted conversation, and the quick-context notes field (`JudgmentRequest.combinedFreeText`) — so risky language can't bypass routing by being placed in a context field instead of the message. When flagged: verdict is always DON'T SEND IT, `isSafetyRouted` is `true`, the reason is a fixed, calm, non-comedic string, and `VerdictView` hides the rewrite and share controls. Crucially, **this check always runs before any network call** — a safety-routed message never reaches the AI model or leaves the device in any form.

## Mechanism 2: Repeated-contact guarding

Unchanged from the first release. `ContextSignals` looks for a short, explicit list of phrases people use to self-report repeated unanswered contact (e.g. "already texted", "called twice"), scanned across quick-context notes and pasted conversation text. When found, it's the first-priority mechanical rule, overriding tone entirely. Also always runs before any network call.

## Mechanism 3: Semantic judgment (self-hosted local model)

`RemoteAIJudgmentProvider` sends the proposed message, goal, and context to theAIgincy's application API (`server/`), which in turn calls a **self-hosted local language model** (via an OpenAI-compatible local inference server — llama.cpp server or Ollama, see `server/README.md`) to reason about:

- hostility, anger, contempt, or profanity — including language with no obvious "angry" words
- passive aggression, sarcasm, guilt-tripping, and manipulative framing (including manipulative affection)
- veiled or indirect threats and coercive language
- desperation, anxiety, or excessive pressure
- repeated contact and unanswered messages — whether the sender is escalating contact unnecessarily
- reciprocity and mismatched tone
- healthy directness, flirting, apologies, boundaries, and closure — recognizing when a message does one of these well, not just the ways a message can go wrong
- escalation, and whether the message actually supports the sender's stated goal

The model is explicitly instructed, in `server/src/lib/prompt.ts`:

- **Never claim certainty about the recipient's private thoughts, feelings, motives, or character** — including never claiming or implying the recipient is definitely cheating, lying, a narcissist, or any other diagnosis of their behavior. It evaluates the *message*, not the recipient — it has only the sender's account of events.
- **Never encourage stalking, harassment, repeated unwanted contact, threats, coercion, retaliation, or humiliation.**
- **Never claim or imply it is a therapist, doctor, lawyer, or relationship counselor.**
- **Return only the structured fields** in the response contract — no free-form commentary, no caveats.
- **The most important rule**: absence of a detected problem is NOT evidence for `send`. `send` requires affirmative evidence that (1) the tone is appropriate, (2) the message advances the stated goal, and (3) the supplied context doesn't contradict sending it. When the model can't confidently say yes to all three, it must prefer `rewrite`, `sleep`, or `need_context` — never guess toward `send`. See "The NEED MORE CONTEXT verdict" below.

The client (`RemoteAIJudgmentProvider`) strictly validates every field of the response before rendering anything (verdict must be a known enum value; reason must be non-empty and bounded; rewrite options are trimmed, filtered, and capped at 3) — a malformed or out-of-contract response is treated as a failure, never rendered as-is. The server independently validates the same schema before ever returning a response. See `API_CONTRACT.md`.

## The NEED MORE CONTEXT verdict

A fifth verdict, `need_context` (`recommended_action: "add_context"`), is a deliberate, first-class answer, not an error state. When the message and goal are clear but the supplied context is too thin to responsibly judge tone/goal-fit/context-consistency, the model is instructed to say so rather than guess in either direction. The app surfaces this as **NEED MORE CONTEXT.** with an **ADD MORE CONTEXT** control that returns the user to Step 3 with everything they already entered intact (`JudgeViewModel.returnToAddContext()`) — never as a dead end, and never disguised as a real judgment on the message. `rewrite_options` is always empty for this verdict, and the rewrite/share controls are hidden, matching `sleep`'s treatment of "there's nothing to send yet."

## The SEND IT invariant

**No local rule anywhere in this app — mechanical, fallback, or otherwise — is ever allowed to return SEND IT.** This is the direct fix for all three reported defects, restated as a standing architectural rule rather than a specific patch:

- `DeterministicJudgmentRules` has no rule that produces `.send` (it did, briefly, in the first redesign — those rules were removed once it became clear that a calm-sounding or reciprocity-supported message still needs an actual read to catch a fake-calm veiled threat or a manipulative "nice" message).
- `FallbackJudgment` — the fully local, last-resort result used when the AI is unavailable — always returns REWRITE IT, never SEND IT, regardless of how "clean" the message looks. Absence of a detected problem is not evidence a message is safe to send; only genuine semantic judgment, or an explicit safety/mechanical override, produces a confident answer.
- The only way this app ever tells a user SEND IT is a real judgment from `RemoteAIJudgmentProvider`'s call to the self-hosted model, and even then only when the model found affirmative evidence for it (see "The most important rule" above) — never merely because nothing was flagged. When that path is unavailable, the user gets an honestly-labeled, conservative local result instead (`isLocalFallback`) — see "Graceful degradation" below.

This is regression-tested directly: `LocalJudgmentProviderFixtureTests.testNeverReturnsSend`, `AdversarialSemanticFixtureTests.testLocalProviderNeverSendsHostileOrManipulativeMessages`, and `DeterministicJudgmentRulesTests.testNeverReturnsSendAcrossASweepOfInputs`. On the server side, `server/scripts/benchmark.ts` reports a "SEND IT false-positive count" against the same 60 fixtures, with a documented threshold of zero — see `server/README.md` → "Model benchmark harness."

## Graceful degradation (never fake confidence)

When the network is unavailable, the request times out, or the server's response fails validation, `RemoteAIJudgmentProvider` does not retry indefinitely or silently substitute a guess — it falls back to `FallbackJudgment`'s conservative local result and marks it `isLocalFallback = true`. `VerdictView` surfaces this honestly: a visible banner ("I can't judge this properly right now — this is a limited, local-only check.") plus a "Try again for full analysis" button that re-runs judgment once the user has a connection. The app never presents a degraded local guess as if it were a considered AI judgment.

## What this deliberately does NOT do

- It does not attempt to diagnose the user or the recipient.
- It does not claim certainty about the other person's future behavior or motives — enforced both by the system prompt (mechanism 3) and by the fixed copy in mechanisms 1–2.
- It does not generate escalation language, threats, or retaliatory suggestions — the safety/mechanical copy is fixed and reviewed; the AI is explicitly instructed against it and its output is schema-constrained (no free-form commentary field exists to escalate in).
- It does not surface a crisis hotline number or claim to be a crisis service.
- It does not log or persist message content anywhere in the pipeline — device, proxy, or otherwise (see `PRIVACY_DATA_MAP.md`).

## Testing

- `SafetyScannerTests.swift` — clean text, each of the six categories, case-insensitivity, non-empty safe response.
- `DeterministicJudgmentRulesTests.swift` — rule ordering/priority, the exact profanity regression, and the blanket never-returns-send sweep.
- `LocalJudgmentProviderFixtureTests.swift` — end-to-end fixtures for every case the deterministic engine resolves confidently and exactly.
- `AdversarialSemanticFixtures.swift` / `AdversarialSemanticFixtureTests.swift` — 60 product-intent fixtures across 15 adversarial categories (profanity, euphemistic hostility, sarcasm, passive aggression, guilt trips, veiled threats, manipulative affection, accusatory questions, bizarre/chaotic text, polite harassment, excessive follow-ups, calm boundaries, healthy directness, genuine apologies, mutual flirting), including the exact regression from the product brief.
- `RemoteAIJudgmentProviderTests.swift` / `MockURLProtocol.swift` — proves the client's local pre-filters, request/response handling, strict validation (including the `need_context`/`add_context` wire mapping), and graceful fallback, without any real network call.
- `RemoteAIJudgmentProviderLiveTests.swift` — runs the same 60 adversarial fixtures against a **real deployed endpoint** once one exists (skipped otherwise); this is the only client-side test that can actually confirm the live model's judgment quality, as opposed to the client's plumbing.
- `server/scripts/benchmark.ts` + `server/benchmark/fixtures.json` — runs the same 60 fixtures directly against a configured local model/inference server, reporting acceptable-verdict rate, SEND IT false positives, critical safety failures, malformed-response rate, and latency against a documented pass/fail threshold. This is the primary tool for choosing which model to deploy — see `server/README.md` → "Model benchmark harness."

## Known limitations (tracked, not blocking)

- Safety and repeated-contact pattern matching (mechanisms 1–2) can still be evaded by misspelling or unusual phrasing — this is why they exist as a fast, always-on safety net rather than the primary judgment mechanism, not as a complete solution.
- Semantic judgment quality (mechanism 3) depends entirely on which local model is deployed. Smaller self-hosted models are generally less reliable than a large hosted frontier model at both following the output-format instructions and at nuanced judgment — this is exactly why `server/scripts/benchmark.ts` exists and why deploying a model that hasn't cleared its documented threshold is not acceptable. Judgment quality has not been verified against a live deployed model in this build environment (no GPU/inference server available) — see `FOUNDER_ACTION_REQUIRED.md`.
- The repeated-contact pattern list only catches phrases in quick-context notes or a pasted conversation, not the proposed message itself — several adversarial fixtures ("polite harassment," "excessive follow-up") are deliberately constructed to land outside this mechanical check and rely on mechanism 3 instead.
- The "critical safety failure" metric in the benchmark harness is a heuristic text scan (looking for the model's own reason/rewrite text violating its "never" instructions), not a guarantee — see the comment in `server/scripts/benchmark.ts` for exactly what it catches and its limits.
