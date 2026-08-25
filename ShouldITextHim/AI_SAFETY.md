# AI Safety — Should I Text Him?

This document is the full rule set governing how the app handles potentially high-risk content, as required by the Day 1 spec's "Safety Routing" section. It is intentionally small and auditable, not a general moderation platform.

## Why this exists

The app's whole job is to react to a message the user is about to send someone else. That message can, in rare cases, itself describe or contain real harm — a threat, a statement of self-harm intent, coercive or stalking language, sexual exploitation, or abusive control language. The product's comedic, sharp tone (see `PRODUCT_SPEC.md` §Tone) is completely wrong for those cases, and helping "rewrite" or "share" such a message would be actively harmful. This layer exists to catch that narrow set of cases and respond differently.

## How detection works

`Engine/SafetyScanner.swift` performs a deterministic, on-device, case-insensitive substring scan of the pasted text against a fixed set of phrase patterns grouped into six categories (`RiskFlag`):

| Category | Examples of matched language |
|---|---|
| `violenceThreat` | "I'll kill you", "you'll pay for this", "watch your back" |
| `selfHarm` | "kill myself", "end my life", "want to die" |
| `coercion` | "if you don't reply I'll…", "you owe me", "send it or I'll…" |
| `stalking` | "I know where you live", "I'm not going to stop texting", "I followed you" |
| `sexualExploitation` | "send nudes or…", "I'll post your pictures" |
| `abuseIndicator` | "you're nothing without me", "you'll never find anyone like me" |

The full pattern list is in code (not duplicated here to avoid this document drifting out of sync with what's actually enforced) — see `SafetyScanner.patterns`.

This is a **pattern list, not a machine-learning classifier**. It is deliberately biased toward over-flagging: a false positive just means a normal message gets a calmer-than-necessary response, while a false negative could let genuinely dangerous language through unfiltered. See `POST_LAUNCH.md` for why a full classifier is out of scope for v1.

## What happens when content is flagged

`JudgmentEngine.judge(_:)` checks `SafetyScanner.scan(_:)` **before** running any of the normal tone-scoring logic. If any risk flag is found:

1. The verdict is always **DON'T SEND IT**.
2. The reason is a fixed, calm, non-comedic string (`SafetyScanner.safeResponse(for:)`):
   > "This message includes language that could seriously harm you or someone else. We're not going to joke about this one — please don't send it as written, and consider talking to someone you trust."
3. `isSafetyRouted` is set to `true` on the result.
4. In `VerdictView`, `isSafetyRouted == true` hides both the **HELP ME REWRITE IT** and **share** controls — the app will not help polish or distribute a message it has flagged as high-risk.
5. **START OVER** remains available so the user isn't stuck.

## What this deliberately does NOT do

- It does not attempt to diagnose the user or the recipient ("you sound like you're in an abusive relationship").
- It does not claim certainty about the other person's future behavior.
- It does not generate any escalation language, threats, or retaliatory suggestions in the reason text — the copy is fixed and reviewed, not generated.
- It does not surface a crisis hotline number or claim to be a crisis service — this is a text-judging utility, not a mental-health or safety product, and overstating that would itself be misleading. If the app grows real usage in this area, adding a calm, optional pointer to a general support resource (without diagnosing) is a candidate for a future iteration — tracked in `POST_LAUNCH.md`, not shipped in v1 to avoid an unreviewed, unsupported claim of care.
- It does not log or transmit the flagged message anywhere — the same zero-persistence, zero-network rule applies to safety-routed content as to everything else (`PRIVACY_DATA_MAP.md`).

## Testing

`SafetyScannerTests.swift` and the safety-routing tests in `JudgmentEngineTests.swift` cover: clean text (no flags), each of the six categories individually, case-insensitivity, and that the safety response is never empty and always maps to DON'T SEND IT with `isSafetyRouted == true`.

## Known limitations (tracked, not blocking)

- Pattern matching can be evaded by misspelling, unusual phrasing, or non-English text. This is a known limitation of a proportionally-scoped v1, not an oversight — see `POST_LAUNCH.md` for the upgrade path (e.g., a remote classifier via `API_CONTRACT.md`, if usage ever justifies the backend and cost).
- The pattern list only inspects the message the user is about to send, not prior context they haven't shared with the app — the tool cannot know what happened before this message.
