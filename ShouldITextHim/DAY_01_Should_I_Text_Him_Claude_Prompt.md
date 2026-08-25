# Claude Build Prompt — Day 1
## App: Should I Text Him?
## Studio: theAIgincy

You are the lead iOS engineer responsible for taking this app from specification to a production-quality, App-Store-submittable build.

Do not create a prototype, mock, demo, or partial implementation. Build the smallest complete production version.

Read and follow `MICRO_APP_FACTORY.md` as the governing engineering and release standard.

---

## Objective

Build a native SwiftUI iPhone app called **Should I Text Him?**

Core promise:

**Before you send the text you may regret, run it through the app.**

The app should feel immediate, funny, polished, lightweight, and useful. The primary user should be able to open the app, paste a text, receive a verdict, and optionally receive a rewrite within seconds.

Avoid unnecessary architecture.

---

## Product Flow

### Screen 1 — Main Input

Display:
- App name: `Should I Text Him?`
- Supporting line: `Before you send it, run it by us.`
- Large multiline text field:
  `Paste what you're about to send...`
- Primary CTA:
  `JUDGE MY TEXT`

Requirements:
- CTA disabled when input is blank/whitespace.
- Clear loading state.
- Keyboard handling must be correct.
- Large-text accessibility must not break layout.
- User can clear/reset easily.

### Screen 2 — Verdict

After analysis, show one highly prominent verdict:

- `SEND IT.`
- `REWRITE IT.`
- `SLEEP ON IT.`
- `DON'T SEND IT.`

Then show:
- one concise explanation
- no unnecessary essay
- button: `HELP ME REWRITE IT`
- button: `START OVER`
- share control for a privacy-safe result card

The share card must NOT include the user's original message by default.

### Rewrite Intent

If user chooses rewrite, ask:

`What are you actually trying to do?`

Options:
- Flirt
- Make plans
- Get clarity
- Apologize
- Set a boundary
- Get closure
- Say less

Return up to 3 concise rewrite options.

Allow copy-to-clipboard.

---

## Tone

The app voice should be:
- funny
- sharp
- confident
- concise
- socially aware
- non-clinical

It must never:
- diagnose the other person
- claim certainty about motives
- tell a user someone is definitely cheating, lying, narcissistic, abusive, etc. from insufficient evidence
- encourage harassment, repeated unwanted contact, stalking, retaliation, threats, coercion, humiliation, or abuse
- imply that the product is therapy, legal advice, medical advice, or professional relationship counseling

When there is insufficient context, say so.

---

## Safety Routing

Implement explicit handling for potentially high-risk content.

Examples:
- threats of violence
- self-harm statements
- coercion
- stalking
- sexual exploitation
- credible abuse situations

Do not turn these into jokes.

The app should return a calm safe response and avoid generating escalation language.

Keep this implementation proportional to the app; do not build a giant moderation platform.

Document all rules in `AI_SAFETY.md`.

---

## AI Architecture

First inspect the repo/environment for an approved existing secure AI backend pattern.

NEVER place an OpenAI API key or any secret inside the iOS app.

If an approved secure proxy/backend already exists:
- use it
- define a minimal API contract
- send the minimum necessary text
- do not persist raw user messages
- do not log raw user messages
- use short bounded outputs
- implement timeout/retry/error states

If no secure backend exists:
- create a clearly documented server-side proxy implementation/configuration appropriate to the existing deployment environment OR
- if that cannot safely be completed in this repo, build the client abstraction and a deterministic local fallback so the app remains functional, and mark the server connection as an explicit release blocker.

Do not fake a production AI connection.

The AI should return structured JSON, conceptually:

{
  "verdict": "send|rewrite|sleep|dont_send",
  "reason": "short reason",
  "risk_flags": [],
  "rewrite_options": []
}

Validate all model output before rendering it.

Use deterministic application-side rules for safety overrides where appropriate.

---

## Persistence

Default behavior:
- no user account
- no conversation history
- no cloud history
- do not store original pasted messages after the active interaction unless technically necessary
- do not write raw user messages to logs

Small nonsensitive preferences may use UserDefaults.

---

## Monetization

Do NOT implement a recurring weekly subscription.

Architect monetization so StoreKit 2 can support a simple one-time unlock/credit product later if needed.

For the first build, prioritize complete core functionality and easy access.

If you implement an IAP in this build:
- use StoreKit 2
- include restore behavior where applicable
- handle purchase failure/cancel/pending states
- document App Store Connect configuration required
- do not block App Review with an unconfigured product

If monetization would slow the initial production release, leave the first version free and document the exact follow-up implementation.

---

## UI / UX

Use native SwiftUI.

Design goals:
- high contrast
- strong typographic hierarchy
- polished but simple
- playful without looking childish
- fast
- minimal screens
- satisfying verdict animation

Do not rely on animation to communicate state.

Respect Reduce Motion.

Support light and dark appearance unless there is a concrete product reason not to.

No unnecessary splash/tutorial carousel.

No account wall.

No fake testimonials.

No dark patterns.

---

## Accessibility

Implement and test:
- VoiceOver labels/hints where useful
- Dynamic Type
- accessible reading/focus order
- adequate tap targets
- sufficient contrast
- non-color-only state communication
- Reduce Motion
- copy button accessibility
- share button accessibility
- text field accessibility

Complete `ACCESSIBILITY_CHECKLIST.md`.

---

## Privacy

Create `PRIVACY_DATA_MAP.md` describing exactly:
- what the user enters
- what remains on-device
- what leaves the device
- which service receives it
- whether identifiers are transmitted
- analytics behavior
- purchase data
- retention
- deletion
- permissions
- tracking

Do not make App Store privacy claims that are not supported by actual code.

Add/validate `PrivacyInfo.xcprivacy` as appropriate for the final dependency/API set.

Do not request ATT permission unless actual cross-app tracking exists and is required.

---

## Security

Run a code-level review for:
- embedded secrets
- sensitive logging
- insecure networking
- overly broad permissions
- unsafe local persistence
- dependency risk
- injection/unsafe rendering
- model-output validation
- unbounded network requests
- crash/error leakage

Write results to `SECURITY_REVIEW.md`.

No known release-blocking security finding may remain silently unresolved.

---

## Required Documents

Create/update:

- `README.md`
- `PRODUCT_SPEC.md`
- `ACCEPTANCE_CRITERIA.md`
- `PRIVACY_DATA_MAP.md`
- `ACCESSIBILITY_CHECKLIST.md`
- `SECURITY_REVIEW.md`
- `AI_SAFETY.md`
- `APP_STORE_METADATA.md`
- `RELEASE_CHECKLIST.md`
- `DECISIONS.md`

---

## App Store Metadata Draft

Create an initial metadata draft in `APP_STORE_METADATA.md`, including:
- app name
- subtitle
- description
- keywords
- category recommendation
- age-rating considerations
- privacy URL placeholder:
  `https://theAIgincy.com/apps/should-i-text-him/privacy`
- support URL placeholder:
  `https://theAIgincy.com/apps/should-i-text-him/support`
- App Review notes
- screenshot shot list
- promotional/social hooks

Do not make claims the app cannot substantiate.

---

## Testing

At minimum cover:
- blank input
- whitespace input
- normal message
- very long input
- multiline input
- API success
- malformed API response
- timeout
- offline/network failure
- high-risk safety-routing example
- verdict reset
- rewrite flow
- copy
- share
- relaunch
- large Dynamic Type
- Reduce Motion behavior

Build and run tests.

Fix failures.

Repeat until green or document a genuine external blocker.

---

## Release Gate

Before declaring completion, verify:

1. Project builds using Apple-current submission tooling.
2. No hardcoded secret exists.
3. Core experience works.
4. Loading/error/offline states work.
5. Safety routing works.
6. Accessibility review is complete.
7. Privacy map matches code.
8. Privacy manifest/dependency requirements are checked.
9. No placeholder copy or dead controls remain.
10. App Store metadata draft exists.
11. Release checklist exists.
12. Tests pass.
13. Compiler warnings are eliminated where reasonably possible.
14. Anything requiring founder/App Store/backend credentials is listed under `FOUNDER_ACTION_REQUIRED`.

---

## Final Response Format

When finished, do not give me a vague summary.

Return:

### BUILT
Exact functionality completed.

### TESTED
Tests/builds performed and results.

### SECURITY / PRIVACY
What was verified.

### APP STORE READINESS
What is ready.

### FOUNDER ACTION REQUIRED
Only actions that require my credentials, Apple account, domain access, physical-device action, or business decision.

### BLOCKERS
Only genuine blockers.

### FILES CHANGED
Concise list.

### NEXT COMMAND
The single best next action for me to take.

Keep the product small. Do not turn this into a large SaaS platform. If you identify a nice-to-have feature that is not required for launch, put it in `POST_LAUNCH.md` rather than implementing it.
