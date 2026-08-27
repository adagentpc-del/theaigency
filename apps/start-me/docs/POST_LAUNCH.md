# Start Me — Post-Launch Ideas

Deliberately **not** in V1. Each of these was considered and deferred
because it doesn't directly improve "I'm stuck -> I physically started" —
the one test every V1 feature had to pass (spec §"Final product rule").
Nothing here should be built until real usage data justifies it.

## Widget

A home-screen widget ("Start one thing." — tap opens task entry directly)
per spec §31. Not built in V1 per the spec's own instruction: only add a
widget once the app is otherwise fully finished, tests pass, and release
readiness is complete, and only if it adds virtually no risk. None of
those preconditions are met yet (see `FOUNDER_ACTION_REQUIRED.md`).

## Optional local reminders

Spec §30 explicitly forbids requesting notification permission at first
launch, and prefers no reminder feature at all in V1. A future
user-initiated, opt-in "remind me to start something" local notification
could be added later, requesting permission only at the moment the user
asks for it — never on launch.

## One-time Pro unlock

See `docs/MONETIZATION.md`. Extra themes, custom timer lengths, expanded
stats, additional starter-action packs — all deferred until usage data
exists.

## Expanded stats / dashboard

The spec is explicit that stats should stay a single no-shame line, not a
dashboard. If users clearly want more (e.g. a review mentioning it),
consider a very light expansion — never a "productivity dashboard," which
the spec explicitly rules out as a category the whole app must avoid
becoming.

## Recent-task quick-restart

Start Me currently stores no task text at all (see `docs/DECISIONS.md`).
A future version could offer "start that again" for the last task, kept
strictly local, short-lived, and clearly removable, if user feedback shows
people want to resume an interrupted task rather than typing it again.
This would need a fresh privacy review before shipping (new entry in
`PRIVACY_DATA_MAP.md`, updated `PrivacyInfo.xcprivacy`).

## More starter-action variety

`Engine/StarterActionLibrary.swift` currently has 3–4 hand-authored
variants per category. More variety (especially for the highest-traffic
categories, once usage data identifies them) would reduce repetition for
frequent users without changing the product's shape.

## Better classification

If a specific category is misfiring often in real usage (the classifier's
known limitations are documented in `docs/PRODUCT_QA.md`), tune
`TaskStarterEngine.classify(_:)`'s keyword lists — but keep it a compact,
understandable router, not a step toward a full NLP/ML system, which
would reintroduce exactly the complexity and cost this app was built to
avoid.

## Apple Watch companion

A one-screen "type or dictate the thing, get the tiny action, start the
timer" watch app could fit the product's own philosophy well (immediate,
tiny, no plan) — worth considering once the iPhone app has validated
demand.
