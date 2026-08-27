# Start Me — Release Checklist

Legend: **Done** (verified in this environment) / **Unverified** (needs
Xcode, a simulator, or a physical device — none available in this build
environment) / **Blocked** (needs a founder action first).

## Build

- [ ] Unverified — `StartMe` scheme builds in Xcode. The project file was
      hand-generated and structurally validated (balanced object graph,
      every build-phase file reference resolves to a real file on disk,
      target IDs cross-referenced consistently between `project.pbxproj`
      and the shared scheme) but has never actually been opened or
      compiled by Xcode. **First action for whoever has Xcode: open
      `apps/start-me/StartMe.xcodeproj` and build the `StartMe` scheme.**
- [ ] Unverified — `StartMeTests` run and pass. All 79 fixtures + ~45
      other test methods across 10 test files were written against the
      real implementation and manually traced for correctness (see
      `docs/ACCEPTANCE_CRITERIA.md`), but never executed by the Swift
      compiler/XCTest runner.
- [x] Done — `ShouldITextHim` (the sibling app) was not modified. Verified
      via `git status`/`git diff` showing changes confined to
      `apps/start-me/`, the new root `.gitignore`, and `README.md` — see
      §"Regression protection" below.
- [ ] Unverified — Release configuration archive/export.

## Product

- [x] Done — Task entry, classification, fallback, alternate start,
      smaller action, stats, and clear-data logic are all covered by
      passing-by-inspection unit tests (see `ACCEPTANCE_CRITERIA.md`).
- [ ] Unverified — 60-second timer and 5-minute continuation on a real
      clock/device (logic verified against a fake clock only).

## Accessibility

See `docs/ACCESSIBILITY_CHECKLIST.md`. Implemented in code: VoiceOver
labels/headers, Dynamic Type via text styles, 44pt minimum tap targets,
semantic contrast-safe colors, Reduce Motion handling, no per-second timer
announcements. **Unverified: an actual VoiceOver swipe-through, Dynamic
Type at AX sizes, and Reduce Motion on a real device.**

## Privacy

- [x] Done — `PrivacyInfo.xcprivacy` present and accurate (empty collected-
      data-types array, no tracking).
- [x] Done — `docs/PRIVACY_DATA_MAP.md` written and matches source.
- [ ] Blocked — Privacy URL (`https://theAIgincy.com/apps/start-me/privacy`)
      is not live. See `FOUNDER_ACTION_REQUIRED.md`.
- [ ] Blocked — Support URL (`https://theAIgincy.com/apps/start-me/support`)
      is not live. See `FOUNDER_ACTION_REQUIRED.md`.
- [ ] Unverified — App Store Connect "App Privacy" questionnaire has not
      been filled in (no App Store Connect access in this environment);
      recommended answers are in `PRIVACY_DATA_MAP.md`.

## Device

- [ ] Unverified — Simulator run (no macOS/Xcode available here).
- [ ] Unverified — Physical iPhone run.
- [ ] Unverified — Clean install.
- [ ] Unverified — Relaunch (persistence logic is unit-tested against a
      fake `UserDefaults` suite, not the real relaunch path).
- [ ] Unverified — Background/foreground (timer elapsed-time logic is
      unit-tested against a fake clock, not real backgrounding).
- [ ] Unverified — Light mode visual check.
- [ ] Unverified — Dark mode visual check.

## Store

- [x] Done — Draft title/subtitle/description/keywords/review notes in
      `docs/APP_STORE_METADATA.md`.
- [ ] Blocked — App icon artwork does not exist (asset slot only). See
      `FOUNDER_ACTION_REQUIRED.md`.
- [ ] Blocked — Screenshots do not exist (require a running build). See
      `FOUNDER_ACTION_REQUIRED.md`.
- [ ] Unverified — Age rating questionnaire (recommended answers drafted
      in `APP_STORE_METADATA.md`; must be entered in App Store Connect).
- [ ] Blocked — Privacy/Support URLs must be live before submission.

## Regression protection (spec §48)

Explicitly verified in this session:

- [x] `ShouldITextHim/` directory tree is untouched — no files were
      read-modified-written under it; only `apps/start-me/`, a new root
      `.gitignore`, and root `README.md` were added/changed.
- [x] No existing branch was overwritten — all work happened on
      `claude/start-me-ios-build-b4ppe9`, a new branch, off the default
      branch.
- [x] Root-level `MICRO_APP_FACTORY.md` conventions (bundle ID pattern
      `com.theaigincy.*`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`,
      `SWIFT_VERSION = 5.0`, doc filenames) were read from
      `ShouldITextHim/MICRO_APP_FACTORY.md` and mirrored, not duplicated
      or forked with different conventions.
- [x] Start Me has zero source-level dependency on `ShouldITextHim` — no
      shared Swift files, no shared Xcode project, no shared target.
- [x] Start Me can be opened, built, and worked on independently by
      opening only `apps/start-me/StartMe.xcodeproj`.

## Definition of done — not yet met

This release is **not** ready to submit. The blockers are: no Xcode build
has ever been run against this code, the app icon doesn't exist, no
screenshots exist, and the privacy/support URLs are not live. See
`docs/FOUNDER_ACTION_REQUIRED.md` for the exact next steps and
`docs/ACCEPTANCE_CRITERIA.md` for the full verified/unverified breakdown.
