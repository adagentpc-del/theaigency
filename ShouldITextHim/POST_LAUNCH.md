# Post-Launch — deferred, not required for v1

Nice-to-haves identified during the build that are explicitly out of scope for the first submission, per the Factory doc's instruction to keep launches small.

## Monetization

- One-time unlock/credit product via StoreKit 2 (per Day 1 spec, architected to support this later): e.g. unlimited judgments free, or a small one-time "Pro" unlock for unlimited rewrites/no soft cap. Requires: App Store Connect product configuration, restore-purchases handling, purchase failure/cancel/pending states — none of which should block the free v1.

## AI backend

- A real hosted-model judgment engine behind theAIgincy's own server-side proxy, per `API_CONTRACT.md`, if/when the local heuristic proves the product's core loop and usage justifies the operating cost. Would materially improve nuance on messages the current keyword/pattern engine handles generically.
- Specifically: real understanding of a **pasted conversation** (Step 3, Option A) — who said what, how long ago, the emotional arc — is exactly the gap the local engine deliberately leaves unfilled today (see `DECISIONS.md` decision 9). It currently gives pasted conversations a conservative, honestly-labeled response rather than pretending to understand them; an AI-backed provider is the natural place to close that gap, likely before extending quick-context reasoning further since that path already works well deterministically.
- If added, extend `AI_SAFETY.md`'s pattern list with a second-pass classifier for higher recall on safety routing (misspellings, non-English text, indirect phrasing) — tracked here rather than v1 because it requires the same backend investment as above.

## Sharing

- A branded, rendered image share card (via `ImageRenderer`) instead of the current plain-text share, for a stronger TikTok/social hook per the Factory doc's "short-form content hook" requirement.

## Personalization (opt-in only)

- A tiny nonsensitive preference or two via `UserDefaults` (e.g. remembering the last-used goal) if user feedback shows it's wanted — must come with a `PrivacyInfo.xcprivacy` update declaring the `UserDefaults` required-reason API usage.

## Analytics

- Minimal, privacy-respecting event instrumentation per the Factory doc §12 (`app_open`, `first_action_started`, `first_action_completed`, `result_created`, `share_started`, `share_completed`, `return_session`) — deferred because it would be the first thing in this app to leave the device in any form, and that's a big enough change to deserve its own privacy-map update and explicit founder sign-off rather than being bundled into Day 1. App Store Connect's built-in metrics (impressions, downloads, crashes) are sufficient to evaluate the initial experiment per the Factory doc.

## Safety

- A calm, optional, non-diagnostic pointer to a general support resource for safety-routed self-harm content, if usage data shows this path is hit meaningfully often — deliberately not shipped in v1 to avoid making an unreviewed claim of care (see `AI_SAFETY.md`).

## Platform

- iPad-optimized layout beyond the current adaptive single-column view (the app supports iPad today via `TARGETED_DEVICE_FAMILY`, but no iPad-specific layout pass has been done).
- Landscape polish beyond the default adaptive behavior.

None of the above are required for the app to be complete, correct, or submittable. Ship v1 first; revisit this list only if the app shows the "Iterate" signals described in `MICRO_APP_FACTORY.md` §14.
