# Start Me — Privacy Data Map

Per `MICRO_APP_FACTORY.md` §8. This document must match the shipped
binary's actual behavior — it is written directly from the source in this
repo, not aspirationally.

## What data exists, and where

| Data | Entered by user? | Stored locally? | Transmitted off-device? | Where in code |
|---|---|---|---|---|
| Task text ("clean my kitchen") | Yes | **No — never persisted** | No | `Features/Home/HomeViewModel.swift` (`taskText` is in-memory `@Published` state only, cleared when the view model deallocates); `Engine/TaskStarterEngine.swift` reads it, computes an action, and discards it |
| Generated starter action text | No (derived) | No | No | In-memory only, per `AppScreen` case |
| Per-day start counts | No (derived) | **Yes** — `UserDefaults`, key `startme.stats.dayCounts.v1`, JSON-encoded `[String: Int]` keyed by `yyyy-MM-dd` | No | `Persistence/StatsStore.swift` |
| Continuation count | No (derived) | **Yes** — `UserDefaults`, key `startme.stats.continuedCount.v1`, integer | No | `Persistence/StatsStore.swift` |
| Haptics on/off preference | Yes (toggle) | **Yes** — `UserDefaults`, key `startme.settings.hapticsEnabled.v1`, boolean | No | `Persistence/SettingsStore.swift` |

That is the complete list. There is no other persistence mechanism
anywhere in the app target (no `SwiftData`/Core Data model, no files
written to disk, no Keychain usage, no third-party SDK).

## Data never collected

- No name, email, phone number, or any account identifier — there is no
  account.
- No advertising or analytics identifier of any kind.
- No device identifier beyond what iOS/Apple infrastructure itself
  necessarily has (App Store Connect metrics only, post-launch — see
  `MICRO_APP_FACTORY.md` §12).
- No Contacts, Photos, Camera, Location, Microphone, Health, or Bluetooth
  access — the app never requests any of these entitlements (see
  `Info.plist`, which contains no usage-description keys for any of them).
- No task text, ever, in any persisted store, log, or crash report path
  that this codebase controls.

## Third parties

None. Start Me makes zero network requests. There is no analytics SDK, no
advertising SDK, no crash-reporting SDK, and no backend of any kind. This
is verifiable directly: `grep -r "URLSession\|URLRequest\|WKWebView" StartMe/`
returns no matches (see `docs/SECURITY_REVIEW.md`).

## Retention & deletion

- Task text: not retained at all (nothing to delete).
- Aggregate stats and the haptics preference: retained until the user
  deletes the app, or taps **Settings > Clear Local Data**, which calls
  `StatsStore.clearAllData()` and removes both `UserDefaults` keys
  immediately. The haptics preference is a UI setting, not "data" in the
  privacy sense, and is left untouched by Clear Local Data (it resets only
  if the user deletes the app).

## Permissions

None requested. Start Me never presents an iOS permission prompt in V1
(no notifications on launch or otherwise — see `PRODUCT_SPEC.md` §"What
Start Me is not" and the "no notification permission on launch" rule).

## Tracking status (App Store Privacy questionnaire)

**Start Me does not track users**, as Apple defines tracking (linking
data with third-party data for advertising, or sharing with a data
broker). Recommended App Store Connect answers:

- "Does this app track users?" → **No**.
- "Data collected" → **None** (aggregate local stats are not "collected"
  in Apple's sense because they never leave the device and are not linked
  to identity).

`PrivacyInfo.xcprivacy` reflects this: `NSPrivacyCollectedDataTypes` is an
empty array, `NSPrivacyTracking` is `false`, `NSPrivacyTrackingDomains` is
empty.

## Founder action required

- Confirm the App Store Connect "App Privacy" questionnaire answers match
  this document at submission time (Apple's questionnaire UI changes
  periodically — re-verify current wording, don't assume).
- Publish the live privacy policy at
  `https://theAIgincy.com/apps/start-me/privacy` before submission — see
  `docs/FOUNDER_ACTION_REQUIRED.md`.
