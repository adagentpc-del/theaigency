# AI Safety — Should I Text Him?

This document is the full rule set governing how the app handles potentially high-risk content and repeated/unwanted-contact patterns. It is intentionally small and auditable, not a general moderation platform.

## Two distinct mechanisms

The product brief's "never encourage harassment, repeated unwanted contact, stalking, retaliation, threats, coercion, humiliation, or abuse" requirement is enforced by two separate, independently-tested mechanisms — it's worth being precise about which is which:

1. **Safety routing** (`SafetyScanner`) — catches high-risk *language* (threats, self-harm statements, coercive or stalking phrasing, sexual exploitation, abusive control language) regardless of goal or context, and always wins.
2. **Repeated-contact guarding** (`DeterministicJudgmentRules`, rule 1) — catches a *pattern* the user has self-reported (already texted/called more than once without a response), even when the proposed message itself is perfectly polite, and routes to DON'T SEND IT.

Both exist because a message can be a problem for either reason independently: "I'll make you regret this" is dangerous language regardless of context; "Just checking if you got my message" is completely benign language that becomes a problem only in light of "this is the third time I've texted since he didn't answer."

## Why this exists

The app's whole job is to react to a message the user is about to send someone else. That message — or the context around it — can, in rare cases, describe or contain real harm, or represent the start of a pattern the user shouldn't be encouraged to continue. The product's comedic, sharp tone (see `PRODUCT_SPEC.md` §Tone) is completely wrong for those cases, and helping "rewrite" or "share" such a message would be actively harmful. These mechanisms exist to catch that narrow set of cases and respond differently.

## Mechanism 1: Safety routing

### How detection works

`Engine/SafetyScanner.swift` performs a deterministic, on-device, case-insensitive substring scan against a fixed set of phrase patterns grouped into six categories (`RiskFlag`):

| Category | Examples of matched language |
|---|---|
| `violenceThreat` | "I'll kill you", "you'll pay for this", "watch your back" |
| `selfHarm` | "kill myself", "end my life", "want to die" |
| `coercion` | "if you don't reply I'll…", "you owe me", "send it or I'll…" |
| `stalking` | "I know where you live", "I'm not going to stop texting", "I followed you" |
| `sexualExploitation` | "send nudes or…", "I'll post your pictures" |
| `abuseIndicator` | "you're nothing without me", "you'll never find anyone like me" |

The full pattern list is in code (not duplicated here to avoid this document drifting out of sync with what's actually enforced) — see `SafetyScanner.patterns`.

This is a **pattern list, not a machine-learning classifier**. It is deliberately biased toward over-flagging: a false positive just means a normal message gets a calmer-than-necessary response, while a false negative could let genuinely dangerous language through unfiltered.

### What is scanned

As of the context-aware redesign, the scan covers **every piece of free text the user can enter**, not just the proposed message: the proposed message, the pasted conversation (if that context option is used), and the optional quick-context notes field (`LocalJudgmentProvider.safetyScanText(for:)`). This closes a gap where risky language could otherwise be typed into a context field instead of the message field.

### What happens when content is flagged

`LocalJudgmentProvider.judge(_:)` checks `SafetyScanner.scan(_:)` **before** running any goal/context/tone reasoning. If any risk flag is found:

1. The verdict is always **DON'T SEND IT**.
2. The reason is a fixed, calm, non-comedic string (`SafetyScanner.safeResponse(for:)`):
   > "This message includes language that could seriously harm you or someone else. We're not going to joke about this one — please don't send it as written, and consider talking to someone you trust."
3. `isSafetyRouted` is set to `true` on the result.
4. In `VerdictView`, `isSafetyRouted == true` hides both the **HELP ME REWRITE IT** and **share** controls — the app will not help polish or distribute a message it has flagged as high-risk.
5. **START OVER** remains available.

## Mechanism 2: Repeated-contact guarding

`Engine/ContextSignals.swift` looks for a short, explicitly-scoped list of phrases people commonly use to self-report that they've already reached out more than once (e.g. "already texted", "called twice", "texted him again"), scanned across quick-context notes and pasted conversation text. When found, `DeterministicJudgmentRules` returns DON'T SEND IT as its **first-priority rule**, ahead of every tone-based rule, with a reason that names the pattern directly rather than commenting on the new message's wording:

> "You've already reached out more than once without a response. Sending another message right now risks feeling like pressure instead of connection — give it real space."

This is not safety routing (`isSafetyRouted` stays `false` — nothing here is dangerous language), but it uses the same principle: a self-reported fact about the situation overrides everything else the engine would otherwise conclude from tone alone.

## What this deliberately does NOT do

- It does not attempt to diagnose the user or the recipient ("you sound like you're in an abusive relationship").
- It does not claim certainty about the other person's future behavior or motives.
- It does not generate any escalation language, threats, or retaliatory suggestions in the reason text — the copy is fixed and reviewed, not generated.
- It does not surface a crisis hotline number or claim to be a crisis service — this is a text-judging utility, not a mental-health or safety product, and overstating that would itself be misleading (see `POST_LAUNCH.md` for why a calm resource pointer is deferred rather than shipped unreviewed).
- It does not log or transmit flagged content anywhere — the same zero-persistence, zero-network rule applies to safety-routed and repeated-contact-guarded content as to everything else (`PRIVACY_DATA_MAP.md`).
- It does not attempt to infer repeated-contact patterns from tone or from a pasted conversation's structure — only from explicit self-reported phrases, to avoid re-growing a brittle keyword list under a different name (see `DECISIONS.md`, decision 9).

## Testing

- `SafetyScannerTests.swift` — clean text, each of the six categories individually, case-insensitivity, non-empty safe response.
- `LocalJudgmentProviderFixtureTests.swift` — four end-to-end safety fixtures (violence, self-harm, stalking, coercion) confirming safety routing overrides goal and context entirely, plus three repeated-contact fixtures confirming that mechanism independently.
- `DeterministicJudgmentRulesTests.testRepeatedContactAlwaysWinsRegardlessOfTone` — confirms rule ordering.

## Known limitations (tracked, not blocking)

- Pattern matching (both mechanisms) can be evaded by misspelling, unusual phrasing, or non-English text. This is a known limitation of a proportionally-scoped deterministic engine, not an oversight — see `POST_LAUNCH.md` and `API_CONTRACT.md` for the AI-backed upgrade path if usage ever justifies it.
- The repeated-contact pattern list only catches *self-reported* repetition (the user telling the app they've already reached out). It does not infer repetition from a pasted conversation's actual message count — deliberately, per decision 9 in `DECISIONS.md`.
