# AI Safety — Should I Text Him?

This document is the full rule set governing how the app judges messages and handles potentially high-risk content and repeated/unwanted-contact patterns. Two QA passes on physical devices found real defects here; this revision describes the architecture that fixes both.

## History: two defects, two fixes

1. **First defect**: the original engine judged the pasted message in isolation, with no knowledge of the user's goal or what had happened before it, and defaulted to SEND IT far too often. **Fix**: judgment became a 3-step flow (message, goal, context) and the engine started reasoning about goal+context together (`DeterministicJudgmentRules`, `ContextSignals`).
2. **Second defect**: even with goal and context, a purely keyword-based engine still couldn't recognize hostility, sarcasm, passive aggression, manipulation, or profanity outside a fixed phrase list — `"hello gangster what the fuck is your problem"` still returned SEND IT, because it matched no keyword. **Fix**: primary judgment became genuinely semantic, via `RemoteAIJudgmentProvider` calling a hosted AI model through theAIgincy's own server-side proxy. The deterministic engine's role changed from "the judge" to "the safety net and the offline fallback" — see `DECISIONS.md` for the full architectural rationale.

## Three mechanisms, in priority order

1. **Safety routing** (`SafetyScanner`) — catches high-risk *language* (threats, self-harm statements, coercive or stalking phrasing, sexual exploitation, abusive control language) regardless of goal, context, or network availability, and always wins. Runs first, entirely on-device, for every single request.
2. **Repeated-contact guarding** (`DeterministicJudgmentRules`, rule 1) — catches a self-reported *pattern* (already texted/called more than once without a response), even when the proposed message itself is polite. Runs second, entirely on-device.
3. **Semantic judgment** (`RemoteAIJudgmentProvider`) — for everything mechanisms 1 and 2 don't resolve, a real AI model reads the actual message, goal, and context and judges whether sending it is advisable. This is now the **primary** path for the app's core "is this OK to send" question — see `API_CONTRACT.md` for the exact contract and `server/lib/prompt.ts` for what the model is instructed to do.

A few purely mechanical facts (a message over 120 words, explicit breakup-topic phrases, having just texted moments ago, a long silence with no positive signal, an unanswered direct question) are still resolved locally too (`DeterministicJudgmentRules`, rules 3–6) — not because tone matters less, but because these are structural facts a network call adds no value in confirming, and resolving them locally is faster and free. **None of these mechanical rules, and no local rule anywhere in this app, is ever allowed to return SEND IT** — see "The SEND IT invariant" below.

## Mechanism 1: Safety routing

Unchanged from the first release. `SafetyScanner` performs a deterministic, on-device, case-insensitive substring scan against six categories (`RiskFlag`): `violenceThreat`, `selfHarm`, `coercion`, `stalking`, `sexualExploitation`, `abuseIndicator`. The scan covers **every piece of free text the user can enter** — the proposed message, the pasted conversation, and the quick-context notes field (`JudgmentRequest.combinedFreeText`) — so risky language can't bypass routing by being placed in a context field instead of the message. When flagged: verdict is always DON'T SEND IT, `isSafetyRouted` is `true`, the reason is a fixed, calm, non-comedic string, and `VerdictView` hides the rewrite and share controls. Crucially, **this check always runs before any network call** — a safety-routed message never reaches the AI model or leaves the device in any form.

## Mechanism 2: Repeated-contact guarding

Unchanged from the first release. `ContextSignals` looks for a short, explicit list of phrases people use to self-report repeated unanswered contact (e.g. "already texted", "called twice"), scanned across quick-context notes and pasted conversation text. When found, it's the first-priority mechanical rule, overriding tone entirely. Also always runs before any network call.

## Mechanism 3: Semantic judgment (new)

`RemoteAIJudgmentProvider` sends the proposed message, goal, and context to theAIgincy's server-side proxy, which prompts Claude to reason about:

- hostility, anger, contempt, or profanity — including language with no obvious "angry" words
- passive aggression, sarcasm, guilt-tripping, and manipulative framing (including manipulative affection)
- veiled or indirect threats and coercive language
- desperation, anxiety, or excessive pressure
- whether the message actually supports the sender's stated goal
- reciprocity and unanswered messages — whether the sender is escalating contact unnecessarily
- mismatched tone
- whether the tone is healthy and direct (good) vs. manipulative or hostile (not)

The model is explicitly instructed, in `server/lib/prompt.ts`:

- **Never claim certainty about the recipient's private thoughts, feelings, motives, or character.** It evaluates the *message*, not the recipient — it has only the sender's account of events.
- **Never encourage harassment, repeated unwanted contact, threats, retaliation, or humiliation.**
- **Never claim or imply it is a therapist, doctor, lawyer, or relationship counselor.**
- **Return only the structured fields** in the response contract — no free-form commentary, no caveats.

The client (`RemoteAIJudgmentProvider`) strictly validates every field of the response before rendering anything (verdict must be a known enum value; reason must be non-empty and bounded; rewrite options are trimmed, filtered, and capped at 3) — a malformed or out-of-contract response is treated as a failure, never rendered as-is. See `API_CONTRACT.md`.

## The SEND IT invariant

**No local rule anywhere in this app — mechanical, fallback, or otherwise — is ever allowed to return SEND IT.** This is the direct fix for both reported defects, restated as a standing architectural rule rather than a specific patch:

- `DeterministicJudgmentRules` has no rule that produces `.send` (it did, briefly, in the first redesign — those rules were removed once it became clear that a calm-sounding or reciprocity-supported message still needs an actual read to catch a fake-calm veiled threat or a manipulative "nice" message).
- `FallbackJudgment` — the fully local, last-resort result used when the AI is unavailable — always returns REWRITE IT, never SEND IT, regardless of how "clean" the message looks. Absence of a detected problem is not evidence a message is safe to send; only genuine semantic judgment, or an explicit safety/mechanical override, produces a confident answer.
- The only way this app ever tells a user SEND IT is a real judgment from `RemoteAIJudgmentProvider`'s call to the model. When that path is unavailable, the user gets an honestly-labeled, conservative local result instead (`isLocalFallback`) — see "Graceful degradation" below.

This is regression-tested directly: `LocalJudgmentProviderFixtureTests.testNeverReturnsSend`, `AdversarialSemanticFixtureTests.testLocalProviderNeverSendsHostileOrManipulativeMessages`, and `DeterministicJudgmentRulesTests.testNeverReturnsSendAcrossASweepOfInputs`.

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
- `RemoteAIJudgmentProviderTests.swift` / `MockURLProtocol.swift` — proves the client's local pre-filters, request/response handling, strict validation, and graceful fallback, without any real network call.
- `RemoteAIJudgmentProviderLiveTests.swift` — runs the same 60 adversarial fixtures against a **real deployed endpoint** once one exists (skipped otherwise); this is the only test that can actually confirm the live model's judgment quality, as opposed to the client's plumbing.

## Known limitations (tracked, not blocking)

- Safety and repeated-contact pattern matching (mechanisms 1–2) can still be evaded by misspelling or unusual phrasing — this is why they exist as a fast, always-on safety net rather than the primary judgment mechanism, not as a complete solution.
- Semantic judgment quality (mechanism 3) depends on the deployed model and prompt, and has not been verified against a live endpoint in this environment — see `RemoteAIJudgmentProviderLiveTests.swift` and `FOUNDER_ACTION_REQUIRED.md`.
- The repeated-contact pattern list only catches phrases in quick-context notes or a pasted conversation, not the proposed message itself — several adversarial fixtures ("polite harassment," "excessive follow-up") are deliberately constructed to land outside this mechanical check and rely on mechanism 3 instead.
