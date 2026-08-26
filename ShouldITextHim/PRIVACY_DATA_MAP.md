# Privacy Data Map — Should I Text Him?

This document describes exactly what the shipped code does. It is the source of truth for the App Store Privacy questionnaire — see `APP_STORE_METADATA.md`.

## Revision note (semantic judgment architecture)

A second QA pass found that the fully on-device, keyword-based engine could not reliably judge hostility, sarcasm, manipulation, or profanity outside a fixed phrase list (see `DECISIONS.md`). The fix required making **primary** judgment semantic, via a server-side proxy calling a hosted AI model. This is the first version of this app where user-entered content leaves the device in normal operation — everything below reflects that honestly. Safety-critical routing and a few structural checks still happen fully on-device first and never require the network (see "What leaves the device").

## What the user enters

Across the 3-step input flow:

- **Step 1**: the text of the message they're considering sending, typed or pasted into a single text field (`proposedMessage`).
- **Step 2**: a selection from a fixed list of 7 goals (e.g. "Apologize").
- **Step 3**: either (a) a pasted excerpt of a recent conversation (`conversationText`), or (b) three closed-choice answers (who texted last, how long since the last message, whether the other person responded) plus one optional short free-text note (`quickAdditionalNotes`).

## What remains on-device

- **Not** written to `UserDefaults`, any file, database, or cache, on-device or server-side.
- **Not** logged via `print`, `os_log`, or any crash/analytics tool on-device, and — per `server/api/judge.ts` — never logged with content server-side either (only an error *type*, e.g. `"timeout"`, is ever logged, never the message).
- Cleared from the app's memory whenever the user taps START OVER or force-quits/relaunches the app (nothing survives process death — there is no persistence layer to survive it). `JudgeViewModel.reset()` clears the message, the selected goal, the context method, the pasted conversation, and all quick-context answers together.
- The server (`server/api/judge.ts`) is a stateless function with no database — a request's content exists only for the duration of that single request/response cycle, then is gone.

## What leaves the device

**Only when semantic judgment actually runs**, and only the three fields that make up a `JudgmentRequest`: the proposed message, the selected goal, and whichever context was provided (pasted conversation or quick-context answers). Sent over HTTPS to theAIgincy's own server-side proxy (`server/`), which forwards a constructed prompt to the Claude API to obtain a judgment, then returns only the structured verdict/reason/rewrite fields — never anything the model provider wouldn't need. See `API_CONTRACT.md` for the exact wire contract.

**Nothing leaves the device when:**
- Deterministic safety rules (`SafetyScanner`) or mechanical rules (`DeterministicJudgmentRules`) resolve the request confidently — these always run first, entirely on-device, for every request, regardless of network availability (see `AI_SAFETY.md`). A meaningful fraction of requests (anything with a repeated-contact disclosure, a clear breakup-topic message, a very long message, or obvious double-texting) never reach the network at all.
- The device is offline, the server is unreachable, or the server's response fails validation — in every one of these cases the app falls back to a fully local, conservative result (`FallbackJudgment`) and nothing is transmitted for that attempt.

No device identifiers, advertising identifiers, account identifiers (there is no account), or any other metadata are ever included in the request — only the three `JudgmentRequest` fields above.

## Which service receives data

- **theAIgincy's own server-side proxy** (`server/`, deployed by the founder — see `server/README.md`), which is the only network endpoint this app ever calls.
- That proxy, in turn, sends a constructed prompt (built from the request's content) to **Anthropic's Claude API** to obtain the judgment. Anthropic processes that request per its own API terms; theAIgincy's proxy does not persist it, and per `server/README.md` never logs its content.
- No other third party receives any data. There is no analytics SDK, no ad SDK, and no other backend.

## Identifiers transmitted

None. The request body is exactly `{ proposedMessage, goal, context }` — no device ID, no advertising ID, no account ID (there is no account), no IP-linked identifier added by the client. (The proxy will incidentally see the calling IP address as part of ordinary HTTP, as any server does — it is not logged or stored; see "Known limitation: abuse mitigation" in `server/README.md`.)

## Analytics

None implemented in this release. See `POST_LAUNCH.md` for the minimal, privacy-respecting event set (`app_open`, `result_created`, etc.) recommended if/when analytics are added — they are **not** in the shipped binary today, and this document will be updated before any analytics ship.

## Advertising

None. No ad SDK is integrated.

## Purchases

None. No IAP is implemented in this release (see `DECISIONS.md`). If a one-time unlock ships later, this document will be updated to describe the StoreKit 2 transaction data Apple's system handles on Apple's servers (Apple ID-linked, not app-collected).

## Retention

- **On-device**: nothing is retained — no field from any of the three input steps outlives the current session.
- **Server-side**: nothing is retained — `server/api/judge.ts` is a stateless function with no database; a request's content exists only in memory for the duration of that one request.
- **At the model provider (Anthropic)**: governed by Anthropic's own API data-handling terms, not by this app. theAIgincy's proxy does not request or configure any extended retention beyond Anthropic's standard API terms.

## Deletion

Not applicable — there is no account and nothing persisted anywhere in the pipeline (device, proxy, or otherwise) to delete. Force-quitting the app discards everything held in its memory.

## Permissions requested

None. The app does not request camera, microphone, contacts, location, photos, notifications, or any other iOS permission. The system Share Sheet is presented via `ShareLink`, which does not require a permission prompt. Network access itself does not require a user-facing permission prompt on iOS.

## Tracking

None. The app does not track users across apps or websites owned by other companies, and does not use IDFA. App Tracking Transparency is not requested, because no tracking exists to disclose. Sending a message's content to theAIgincy's own first-party server to obtain a judgment is not "tracking" under Apple's definition (it is not used to track the user across other companies' apps/websites, and is not combined with third-party data for targeted advertising) — but it is real data transmission, disclosed honestly below and in the App Privacy questionnaire.

## Expected App Store "Privacy Nutrition Label" answers (draft)

| Category | Collected? |
|---|---|
| Contact Info | No |
| Health & Fitness | No |
| Financial Info | No |
| Location | No |
| Sensitive Info | No |
| Contacts | No |
| User Content | **Yes** — the proposed message, goal, and context are sent to theAIgincy's server to obtain a judgment. Not linked to an identity (no account exists), not used for tracking. Purpose: App Functionality only. |
| Browsing History | No |
| Search History | No |
| Identifiers | No |
| Purchases | No |
| Usage Data | No |
| Diagnostics | No |
| Other Data | No |

**This changed from the previous release**, where everything ran on-device and "User Content" was correctly answered "No." Now that semantic judgment transmits content off-device, answering "No" would be false. Re-confirm the exact category wording against Apple's current App Privacy questionnaire at submission time (see `RELEASE_CHECKLIST.md`), since the available sub-options can shift.

## Privacy manifest

`PrivacyInfo.xcprivacy` declares:
- `NSPrivacyTracking = false` — unchanged; this app still does not track.
- `NSPrivacyTrackingDomains = []` — unchanged; no tracking domains.
- `NSPrivacyCollectedDataTypes` — now includes one entry for User Content (not linked to identity, not used for tracking, App Functionality purpose only), matching the table above.
- `NSPrivacyAccessedAPITypes = []` — unchanged; the app still does not call any Apple "required-reason" API (no `UserDefaults`, no file timestamps, no disk-space or system-boot APIs). `URLSession` networking is not a required-reason API.

If any future change adds `UserDefaults`, file timestamp access, or another required-reason API, `PrivacyInfo.xcprivacy` **must** be updated with the matching approved reason code before release.

## Privacy & support URLs

- Privacy: `https://theAIgincy.com/apps/should-i-text-him/privacy`
- Support: `https://theAIgincy.com/apps/should-i-text-him/support`

Both are placeholders per the Factory standard and must be live before submission — see `FOUNDER_ACTION_REQUIRED.md`. The live privacy page **must** be updated to reflect this document's content (data now leaves the device) before submission — do not publish a privacy page written for the fully-offline v1.
