# Founder Action Required — Should I Text Him?

Everything here needs your credentials, hardware, domain access, or a business decision — none of it can be completed autonomously in this build environment.

## 1. Build & test the judgment-flow repair on a real Apple toolchain *(blocker)*

You confirmed the pre-repair build compiled and ran, and your physical-device QA is exactly what surfaced the judgment-logic defect this repair fixes. This repair itself was authored the same way the original build was — in a Linux container with no Xcode/macOS available — so its new/changed files (the whole judgment engine, the new 4-step flow, `Goal`/`QuickContext`/`ContextInput`/`JudgmentRequest`) have **not yet been compiled**. Every file was written and manually reviewed for correctness, and all 34 product QA fixtures were hand-traced against the implementation, but:
- Pull this commit, open `ShouldITextHim.xcodeproj` in current Xcode, and build the `ShouldITextHim` scheme.
- Run the test suite (`Cmd+U`) — pay particular attention to `LocalJudgmentProviderFixtureTests`, which is the direct regression test for the defect you found.
- This is the single most important next step — see `RELEASE_CHECKLIST.md`.

## 2. Physical-device QA of the new flow *(blocker)*

Requires your iPhone. Walk the full 4-step flow (message → goal → context → verdict → optional rewrite → copy/share → start over → relaunch) with several different goal/context combinations — specifically re-test the exact scenario that surfaced the original defect, plus a few from the fixture list in `LocalJudgmentProviderFixtureTests` (healthy flirting, unanswered question, angry message, safety-sensitive input). Then repeat with VoiceOver on, Dynamic Type maxed, and Reduce Motion on across all four steps. Checklist in `RELEASE_CHECKLIST.md` → "Recommended first steps on a Mac."

## 3. App icon artwork

`Assets.xcassets/AppIcon.appiconset/` has a correctly configured single-size (1024×1024) icon slot but **no actual image** — generating real brand/visual identity is a design decision, not something to fabricate as a placeholder. Apple requires a production-quality icon before submission.

## 4. Apple Developer account setup

- Bundle identifier used in this build: `com.theaigincy.shoulditexthim` (test target: `com.theaigincy.shoulditexthim.tests`) — confirm this matches your App Store Connect / Apple Developer team, or change it and re-sign.
- Code signing is currently set to `Automatic` — requires your Apple Developer Program membership and team selection in Xcode.
- TestFlight build upload and internal testing.

## 5. Live privacy & support URLs

`PRIVACY_DATA_MAP.md`/`APP_STORE_METADATA.md` reference:
- `https://theAIgincy.com/apps/should-i-text-him/privacy`
- `https://theAIgincy.com/apps/should-i-text-him/support`

Both are placeholders per the Factory standard. They must resolve to real, accurate pages (the privacy page should reflect `PRIVACY_DATA_MAP.md`) before submission — this requires your domain/hosting access.

## 6. App Store Connect listing

- Create the app record, enter the metadata from `APP_STORE_METADATA.md` (review/adjust the description, keywords, and especially the age-rating questionnaire answers — flagged in that document as needing your judgment call on Apple's current wording).
- Capture real screenshots from a running build per the shot list in `APP_STORE_METADATA.md`.
- Complete the App Privacy questionnaire using `PRIVACY_DATA_MAP.md` as the source of truth.
- Set the final primary/secondary category (Lifestyle recommended).

## 7. Business decisions (non-blocking for v1, but yours to make)

- Whether to launch fully free (current build) or fast-follow with the one-time-unlock StoreKit 2 product described in `POST_LAUNCH.md`.
- Whether/when to invest in a real hosted-AI backend per `API_CONTRACT.md` — not required for v1's product promise, but would improve nuance if the app gets traction.
- Launch content (TikTok/Reels) per the hooks drafted in `APP_STORE_METADATA.md` — actual filming/editing is outside this repo.
- Portfolio tracker entry per `MICRO_APP_FACTORY.md` §13.K — owned by you outside this repo.

## 8. Final submission

Once the above are complete: final QA pass on the TestFlight build, then submit to App Review. Re-check Apple's current submission requirements at that time — `MICRO_APP_FACTORY.md` §10 explicitly notes these are living requirements, not something this document can freeze in time.
