# Post-Launch — deferred, not required for v1

Nice-to-haves identified during the build that are explicitly out of scope for the first submission, per the Factory doc's instruction to keep launches small.

## Monetization

- One-time unlock/credit product via StoreKit 2 (per Day 1 spec, architected to support this later): e.g. unlimited judgments free, or a small one-time "Pro" unlock for unlimited rewrites/no soft cap. Requires: App Store Connect product configuration, restore-purchases handling, purchase failure/cancel/pending states — none of which should block the free v1.

## AI backend hardening

The hosted-model judgment engine (`RemoteAIJudgmentProvider` + `server/`) is now built and is the app's primary judgment path — the items below are follow-ups on top of it, not the backend itself:

- **Server abuse mitigation** — the deployed endpoint currently has no per-caller rate limiting or authentication beyond a payload-size cap (see `server/README.md` → "Known limitation: abuse mitigation" and `SECURITY_REVIEW.md`). Add a KV-backed rate limiter (Vercel KV/Upstash Redis) or Apple DeviceCheck/App Attest before this app has meaningful real-world traffic, to protect against both cost abuse and API quota exhaustion.
- **Deeper pasted-conversation understanding** — the local pre-filter layer deliberately does not deep-parse a pasted conversation's history (see `DECISIONS.md` decision 9), and the server prompt today treats it as one block of context text rather than reasoning over its structure (who said what, how the tone shifted). A natural next step once the current prompt is validated against real usage.
- **Safety pattern-list refinement** — `SafetyScanner`'s deterministic pattern list can still be evaded by misspelling, unusual phrasing, or non-English text. Since it's the safety-critical layer that must work even when the AI is unavailable, improving its recall (rather than routing it through the AI, which would remove the "always works offline" guarantee) is the right direction if usage data shows this matters.
- **Live semantic-quality monitoring** — `RemoteAIJudgmentProviderLiveTests.swift` exists and is ready to run against the deployed server (see `FOUNDER_ACTION_REQUIRED.md`), but there's no ongoing production monitoring of judgment quality (e.g. sampling real verdicts for spot review, tracking how often the local fallback fires). Worth adding once there's real usage to monitor.

## Sharing

- A branded, rendered image share card (via `ImageRenderer`) instead of the current plain-text share, for a stronger TikTok/social hook per the Factory doc's "short-form content hook" requirement.

## Personalization (opt-in only)

- A tiny nonsensitive preference or two via `UserDefaults` (e.g. remembering the last-used goal) if user feedback shows it's wanted — must come with a `PrivacyInfo.xcprivacy` update declaring the `UserDefaults` required-reason API usage.

## Analytics

- Minimal, privacy-respecting event instrumentation per the Factory doc §12 (`app_open`, `first_action_started`, `first_action_completed`, `result_created`, `share_started`, `share_completed`, `return_session`) — still deferred. Judgment requests already leave the device (to theAIgincy's own proxy, for the app's core function), but that's a different thing from an analytics SDK reporting behavioral events to a third party, and adding one is still a big enough change to deserve its own privacy-map update and explicit founder sign-off rather than being bundled in. App Store Connect's built-in metrics (impressions, downloads, crashes) are sufficient to evaluate the initial experiment per the Factory doc.

## Safety

- A calm, optional, non-diagnostic pointer to a general support resource for safety-routed self-harm content, if usage data shows this path is hit meaningfully often — deliberately not shipped in v1 to avoid making an unreviewed claim of care (see `AI_SAFETY.md`).

## Platform

- iPad-optimized layout beyond the current adaptive single-column view (the app supports iPad today via `TARGETED_DEVICE_FAMILY`, but no iPad-specific layout pass has been done).
- Landscape polish beyond the default adaptive behavior.

None of the above are required for the app to be complete, correct, or submittable. Ship v1 first; revisit this list only if the app shows the "Iterate" signals described in `MICRO_APP_FACTORY.md` §14.
