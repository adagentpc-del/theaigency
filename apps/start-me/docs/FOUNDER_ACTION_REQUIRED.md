# Start Me — Founder Action Required

Only items that genuinely need a human with tools/access this build
environment doesn't have. Everything else in the product is built and
covered by `docs/RELEASE_CHECKLIST.md`.

## 1. Open the project in Xcode and build it

No Xcode toolchain exists in this build environment (Linux container).
`apps/start-me/StartMe.xcodeproj` was generated programmatically to mirror
the proven structure of the sibling `ShouldITextHim.xcodeproj`, and was
checked as thoroughly as possible without Xcode itself (balanced object
graph, every referenced file exists on disk, consistent target IDs), but
**it has never actually been opened or compiled.**

**Action:** Open `apps/start-me/StartMe.xcodeproj` in a current version of
Xcode, select the `StartMe` scheme, and build. Fix anything Xcode flags
that a from-scratch structural review couldn't catch (e.g. an Xcode
version-specific project format quirk). Then run the `StartMeTests`
target (`Cmd+U`) — 79 classification fixtures plus roughly 45 other test
methods are ready to run.

## 2. App icon artwork

The `AppIcon.appiconset` asset slot exists
(`StartMe/Assets.xcassets/AppIcon.appiconset/Contents.json`, single
1024×1024 universal slot) but contains no actual image — this build
environment cannot produce production-quality icon artwork. Design
direction is in `docs/APP_STORE_METADATA.md` (movement/ignition, warm
ember-orange, not a checkmark/stopwatch/to-do-list cliché, not
purple/neon-AI styling).

**Action:** Commission or design the icon, add it to the asset catalog.

## 3. Screenshots

No simulator or device was available to run the built app, so no App
Store screenshots exist. A recommended shot list is in
`docs/APP_STORE_METADATA.md` §Screenshots.

**Action:** Once the app builds (item 1), run it in the simulator/device
and capture the five recommended screens at the required device sizes.

## 4. Live Privacy Policy and Support pages

`docs/APP_STORE_METADATA.md`, `docs/PRIVACY_DATA_MAP.md`, and
`Features/Settings/SettingsView.swift` all reference:
- `https://theAIgincy.com/apps/start-me/privacy`
- `https://theAIgincy.com/apps/start-me/support`

Neither is live. App Store submission requires both to resolve to real
pages. `docs/PRIVACY_DATA_MAP.md` has the full, accurate content the
privacy page should reflect.

**Action:** Publish both pages before submission.

## 5. App Store Connect setup

Requires App Store Connect access this environment doesn't have:
bundle ID registration (`com.theaigincy.startme`), app record creation,
entering the draft metadata from `docs/APP_STORE_METADATA.md`, the App
Privacy questionnaire (recommended answers in `docs/PRIVACY_DATA_MAP.md`),
and the age rating questionnaire (recommended answers in
`docs/APP_STORE_METADATA.md`).

**Action:** Create the app record and enter the drafted metadata; re-verify
current Apple requirements first per `MICRO_APP_FACTORY.md` §10 — these
change over time and this document doesn't attempt to be a live source of
truth for them.

## 6. Physical-device QA pass

Everything in `docs/RELEASE_CHECKLIST.md`'s "Device" section — clean
install, relaunch, background/foreground, light/dark mode, VoiceOver,
large text — needs a real device or simulator, neither of which exists
here.

**Action:** Run the physical-device QA pass in
`MICRO_APP_FACTORY.md` §13.G before submitting.

## Not blocked — already done

Everything else in `docs/RELEASE_CHECKLIST.md` marked **Done** required no
special access and was completed in this session: all product logic, all
automated tests (written, not yet run), all required documentation, the
safety layer, the privacy manifest, and the Xcode project structure.
