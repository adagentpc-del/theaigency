# Privacy Data Map — Should I Text Him?

This document describes exactly what the shipped code does. It is the source of truth for the App Store Privacy questionnaire — see `APP_STORE_METADATA.md`.

## What the user enters

Across the 3-step input flow:

- **Step 1**: the text of the message they're considering sending, typed or pasted into a single text field (`proposedMessage`).
- **Step 2**: a selection from a fixed list of 7 goals (e.g. "Apologize").
- **Step 3**: either (a) a pasted excerpt of a recent conversation (`conversationText`), or (b) three closed-choice answers (who texted last, how long since the last message, whether the other person responded) plus one optional short free-text note (`quickAdditionalNotes`).

## What remains on-device

Everything, for every field above. All of it is held only in the `JudgeViewModel`'s in-memory properties for the duration of the current app session. It is:

- **Not** written to `UserDefaults`.
- **Not** written to any file, database, or cache.
- **Not** logged via `print`, `os_log`, or any crash/analytics tool.
- Cleared from memory whenever the user taps START OVER or force-quits/relaunches the app (nothing survives process death — there is no persistence layer to survive it). This includes every step's data, not just the proposed message — `JudgeViewModel.reset()` clears the message, the selected goal, the context method, the pasted conversation, and all quick-context answers together.

The judgment itself (`SafetyScanner`, `MessageSignals`, `ContextSignals`, `DeterministicJudgmentRules`, `FallbackJudgment` — composed by `LocalJudgmentProvider`) runs entirely on-device using deterministic Swift logic — no model inference call, local or remote. See `DECISIONS.md` and `API_CONTRACT.md` for the `JudgmentProvider` abstraction that would apply if a remote engine is introduced later, and the privacy-map update that would require.

## What leaves the device

**Nothing.** This release makes zero network requests. There is no `URLSession` usage, no third-party SDK, and no analytics SDK anywhere in the codebase.

## Which service receives data

None. There is no backend in this release.

## Identifiers transmitted

None — there is nothing to transmit them to.

## Analytics

None implemented in this release. See `POST_LAUNCH.md` for the minimal, privacy-respecting event set (`app_open`, `result_created`, etc.) recommended if/when analytics are added — they are **not** in the shipped binary today, and this document will be updated before any analytics ship.

## Advertising

None. No ad SDK is integrated.

## Purchases

None. No IAP is implemented in this release (see `DECISIONS.md`). If a one-time unlock ships later, this document will be updated to describe the StoreKit 2 transaction data Apple's system handles on Apple's servers (Apple ID-linked, not app-collected).

## Retention

Nothing is retained. No field from any of the three input steps outlives the current session (all are discarded together on START OVER and, trivially, on app termination since none of it was ever persisted).

## Deletion

Not applicable — there is no data to delete, no account, and nothing to reset beyond force-quitting the app (which already discards everything in memory).

## Permissions requested

None. The app does not request camera, microphone, contacts, location, photos, notifications, or any other iOS permission. The system Share Sheet is presented via `ShareLink`, which does not require a permission prompt.

## Tracking

None. The app does not track users across apps or websites owned by other companies, and does not use IDFA. App Tracking Transparency is not requested, because no tracking exists to disclose.

## Expected App Store "Privacy Nutrition Label" answers (draft)

| Category | Collected? |
|---|---|
| Contact Info | No |
| Health & Fitness | No |
| Financial Info | No |
| Location | No |
| Sensitive Info | No |
| Contacts | No |
| User Content | No *(entered but never collected/transmitted/stored beyond the active session — see note below)* |
| Browsing History | No |
| Search History | No |
| Identifiers | No |
| Purchases | No |
| Usage Data | No |
| Diagnostics | No |
| Other Data | No |

**Note on "User Content":** Apple's questionnaire asks about data your app *collects* (i.e., transmits off-device or persists). Text the user types that stays purely in transient on-device memory and is discarded, never transmitted or written to disk, is standard practice to answer "No" for — but re-confirm this against Apple's current guidance at submission time (see `RELEASE_CHECKLIST.md`), since App Review policy on this wording can shift.

## Privacy manifest

`PrivacyInfo.xcprivacy` is present and declares:
- `NSPrivacyTracking = false`
- `NSPrivacyTrackingDomains = []`
- `NSPrivacyCollectedDataTypes = []`
- `NSPrivacyAccessedAPITypes = []` — the app does not call any Apple "required-reason" API (no `UserDefaults`, no file timestamps, no disk-space or system-boot APIs).

If any future change adds `UserDefaults`, file timestamp access, or another required-reason API, `PrivacyInfo.xcprivacy` **must** be updated with the matching approved reason code before release.

## Privacy & support URLs

- Privacy: `https://theAIgincy.com/apps/should-i-text-him/privacy`
- Support: `https://theAIgincy.com/apps/should-i-text-him/support`

Both are placeholders per the Factory standard and must be live before submission — see `FOUNDER_ACTION_REQUIRED.md`.
