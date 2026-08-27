# Start Me — Monetization

## V1: Free

Start Me ships free, with no purchases, no ads, and no account, per
`MICRO_APP_FACTORY.md` §5 ("Launch free when distribution and learning are
more valuable than immediate monetization") and the task's explicit
instruction not to let monetization engineering delay launch.

Explicitly **not** built in V1:
- Subscriptions (weekly, monthly, or annual).
- Credit packs.
- Any StoreKit integration at all — there is no `StoreKit` import
  anywhere in `StartMe/`.

Core task-starting functionality (type a task, get a tiny action, run the
timer, see stats) has no paywall or usage limit of any kind.

## Rationale

Start Me is a zero-marginal-cost, fully local utility — no AI inference
cost, no server cost, no per-use variable cost of any kind. Per the
factory's monetization decision tree, that puts it squarely in "prefer
free, or a one-time unlock" territory, and a free V1 is the right way to
learn whether this specific interaction loop (tiny-action + 60-second
timer) has real retention before investing in monetization engineering.

## Possible future Pro unlock (post-launch only)

If usage data justifies it, a one-time (not subscription) Pro unlock could
add, without changing core functionality for free users:

- Extra visual themes.
- Custom timer lengths (beyond the fixed 60s / 5min).
- Expanded stats (e.g. category breakdowns, longer history).
- A home-screen widget (see `POST_LAUNCH.md`).
- Additional starter-action packs / more variety per category.

None of this is scoped, designed, or built. It is intentionally deferred —
see `POST_LAUNCH.md`.

## Founder action required

- Decide, after real usage data exists, whether a Pro unlock is worth
  building at all. No action needed before launch.
