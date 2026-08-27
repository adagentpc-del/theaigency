# Start Me — Safety

## Why this exists

Start Me turns whatever a user types into an actionable physical first
step. Free-form input can, rarely, describe something the app must never
help make more actionable: self-harm, harming another person, or another
dangerous/illegal act. `Engine/SafetyRouter.swift` exists to catch the
clear, unambiguous cases before they ever reach the starter-action engine.

## What it is — and is not

- It is a small, fully local, deterministic keyword scan
  (`SafetyRouter.triggerPhrases`, ~30 hand-reviewed phrases). It runs
  before classification, on every call to `TaskStarterEngine.starterAction(for:)`
  and `alternateAction(current:originalInput:)`.
- It is **not** a moderation backend, not a classifier, not sentiment
  analysis, and not a crisis-detection or triage system. It cannot
  understand intent, sarcasm, or context beyond literal substring matches.
- It never sends any text off-device to evaluate safety — see
  `docs/PRIVACY_DATA_MAP.md`.

## Behavior when triggered

`SafetyRouter.safeFallbackAction` is returned instead of any real starter
step:

> "That's not something this app can help start."
> "If you or someone else may be in danger, please contact local
> emergency services or a crisis line."

- No smaller-step reductions are offered (`smallerActions` is empty).
- The user's original text is never echoed back in the response.
- The app does not attempt counseling, diagnosis, or triage — it declines
  and points toward real help, nothing more.

## Deliberate false-negative/false-positive trade-offs

- **False positives are treated as more acceptable than false negatives**
  for this narrow set of categories, but the phrase list is kept
  conservative specifically so ordinary benign language ("kill it at my
  presentation," "I could just die of embarrassment," "call and yell at
  customer support") is not swept in. See
  `SafetyRouterTests.test_ordinaryTasks_areNeverFlaggedUnsafe`.
- The list intentionally does **not** try to catch every possible phrasing
  of self-harm or violence — that would require an actual moderation
  system, which is explicitly out of scope for a fully local V1 (see
  `docs/PRODUCT_SPEC.md` §5). This is a first line of defense against
  clear cases, not a safety net for adversarial input.

## Changing the phrase list

`SafetyRouter.triggerPhrases` is the single source of truth. Any edit
must:
1. Keep phrases short and unambiguous (multi-word phrases, not single
   common words) to minimize false positives.
2. Be covered by a test in `SafetyRouterTests.swift` — both a "flags this"
   case and, if the phrase is at all close to ordinary language, a
   corresponding "does not flag this" case.
3. Never log, transmit, or persist the triggering input — the response is
   always the same generic decline regardless of what was typed.

## Founder action required

None for V1 — this is a static, reviewable list shipped in the binary. If
the app ever adds any server-side component (out of scope for V1), safety
routing must be re-reviewed before doing so.
