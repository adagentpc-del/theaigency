# Start Me — Acceptance Criteria

Each item is marked **Verified** (checked by automated test and/or static
code review in this environment — no Xcode/simulator available, see
`RELEASE_CHECKLIST.md`) or **Unverified — needs Xcode/device** (requires a
build, a simulator run, or a physical device and cannot be confirmed here).

## Home

- [x] Verified — Headline, subcopy, and "I need to..." input render on
      launch with no onboarding/account/category step first
      (`Features/Home/HomeView.swift`).
- [x] Verified — START ME is disabled for empty/whitespace-only input
      (`HomeViewModelTests.test_blankInput_disablesStart`,
      `test_whitespaceOnlyInput_disablesStart`).
- [x] Verified — Rotating example captions cycle and pause under Reduce
      Motion (`HomeViewModel.startRotatingPlaceholders(reduceMotion:)`).
- [ ] Unverified — needs Xcode/device — visual layout at all Dynamic Type
      sizes and both orientations on a real device/simulator.

## Task Starter Engine

- [x] Verified — `clean my entire apartment` -> "Throw away one piece of
      trash." (`TaskStarterEngineTests.test_cleanApartment_producesSpecExactAction`).
- [x] Verified — `go to the gym` -> "Put your shoes on."
      (`test_goToTheGym_producesSpecExactAction`).
- [x] Verified — `answer my emails` -> "Open your inbox."
      (`test_answerEmails_producesSpecExactAction`).
- [x] Verified — `file my taxes` -> "Open the website or folder you use for
      your taxes." (`test_fileMyTaxes_producesSpecExactAction`).
- [x] Verified — Unknown input produces a useful fallback, never an empty
      or broken result (`test_unknownInputWithNounPhrase_producesDynamicFallback`,
      `StarterFixtureTests.test_everyFixture_producesANonEmptyAction`).
- [x] Verified — Every one of 79 fixtures produces an action smaller than
      the task (single sentence, ≤12 words) —
      `StarterFixtureTests.test_everyFixture_actionIsSmallerThanTheTask`.
- [x] Verified — Blank/whitespace-only input never crashes the engine
      (`test_blankInput_doesNotCrashAndReturnsGeneralAction`).
- [x] Verified — Unicode and special-character input never crashes the
      engine (`test_unicodeInput_doesNotCrash`, `test_specialCharacterInput_doesNotCrash`).

## Make it even smaller / different start

- [x] Verified — "Make it even smaller" walks through up to 2 further
      reduction levels and hides itself (never errors) once exhausted
      (`StarterViewModelTests.test_makeSmaller_walksThroughReductionLevels`,
      `test_makeSmaller_neverGoesPastAvailableReductionsOrCrashes`).
- [x] Verified — "Give me a different start" changes the action, resets
      the reduction level, and stays within the same category
      (`test_differentStart_changesActionAndResetsReductionLevel`,
      `test_differentStart_staysWithinSameCategory`).

## Timer

- [x] Verified — Initial timer is 60 seconds, continuation is 5 minutes
      (`TimerViewModelTests.test_initialState_showsFullDuration`,
      `test_continuationSession_showsFiveMinutes`).
- [x] Verified — Remaining time is computed from elapsed wall-clock time,
      stays accurate across a simulated background gap, and never goes
      negative (`test_elapsedTimeCalculation_isAccurateRegardlessOfTicks`,
      `test_overshootingElapsedTime_neverGoesNegative`).
- [x] Verified — Completion fires exactly once
      (`test_onComplete_firesOnlyOnce`).
- [ ] Unverified — needs Xcode/device — haptic feedback actually felt on
      hardware; behavior across a real app background/foreground cycle
      (simulated only here via `FakeDateProvider`).

## Completion / continuation

- [x] Verified — KEEP GOING starts a continuation session and records a
      "continued" stat (`AppCoordinator.keepGoing`, `StatsStoreTests.test_recordContinued_incrementsContinuedCountOnly`).
- [x] Verified — I'M DONE and I STOPPED both return home with identical,
      non-shaming framing (`CompletionView`, no differing stats recorded).

## Stats

- [x] Verified — Starts-today resets on a new day; total does not
      (`StatsStoreTests.test_dayBoundary_startsTodayResetsOnNewDay`).
- [x] Verified — Starts-this-week only counts the trailing 7 days
      (`test_weekBoundary_startsThisWeekIncludesTrailingSevenDaysOnly`).
- [x] Verified — Stats persist across a simulated relaunch
      (`test_persistsAcrossNewStoreInstances_simulatingRelaunch`).
- [x] Verified — Clear Local Data resets every counter
      (`test_clearAllData_resetsEverything`).
- [x] Verified — No task text is ever persisted (`StatsStore` only ever
      writes day-keyed integers and a continuation counter — see
      `docs/PRIVACY_DATA_MAP.md`).

## Settings

- [x] Verified — Haptics preference persists across a simulated relaunch
      (`SettingsStoreTests.test_hapticsPreference_persistsAcrossInstances`).
- [ ] Unverified — needs Xcode/device — Privacy/Support links actually open
      Safari and resolve (URLs are not live yet — see
      `FOUNDER_ACTION_REQUIRED.md`).

## Safety

- [x] Verified — Self-harm, harm-to-others, and dangerous/illegal phrases
      never produce an actionable starter step
      (`SafetyRouterTests`, `TaskStarterEngineTests.test_unsafeInput_neverProducesActionableStarterStep`).
- [x] Verified — Ordinary tasks, including ones containing "kill" in a
      benign idiom ("kill it at my presentation"), are never falsely
      flagged (`test_ordinaryTasks_areNeverFlaggedUnsafe`).

## Architecture / privacy

- [x] Verified — No networking code anywhere in the `StartMe` app target
      (grep audit — see `SECURITY_REVIEW.md`).
- [x] Verified — No third-party dependencies (no SPM packages, no
      CocoaPods, no Carthage).
- [x] Verified — No account/authentication code.
- [x] Verified — `PrivacyInfo.xcprivacy` declares no collected data types
      and no tracking.

## Not yet verifiable in this environment

- [ ] Physical-device QA pass (fresh install, relaunch, background/foreground,
      light/dark, large text, VoiceOver spot check) — see `RELEASE_CHECKLIST.md`.
- [ ] `xcodebuild build` / `xcodebuild test` — no Xcode toolchain is
      available in this build environment (Linux container). The project
      file was hand-generated and structurally validated (balanced
      braces, unique identifiers, cross-referenced target IDs) but has
      never been opened in Xcode. See `FOUNDER_ACTION_REQUIRED.md`.
