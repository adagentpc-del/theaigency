# Acceptance Criteria

Each item is written to be objectively checkable on a build. Covered by an automated `XCTest` where noted; otherwise it's a manual/physical-device check (see `RELEASE_CHECKLIST.md`).

## Input screen

- [ ] **AC-1**: With an empty text field, JUDGE MY TEXT is disabled. *(`JudgeViewModelTests.testBlankInputIsInvalid`)*
- [ ] **AC-2**: With a whitespace-only text field, JUDGE MY TEXT is disabled. *(`JudgeViewModelTests.testWhitespaceOnlyInputIsInvalid`)*
- [ ] **AC-3**: With any non-whitespace text, JUDGE MY TEXT is enabled. *(`JudgeViewModelTests.testNormalInputIsValid`)*
- [ ] **AC-4**: A visible Clear control appears once text is entered and empties the field when tapped. *(manual)*
- [ ] **AC-5**: Tapping JUDGE MY TEXT shows a distinct loading state and disables re-submission until a verdict is produced. *(manual — `isJudging` drives this)*
- [ ] **AC-6**: The on-screen keyboard can be dismissed via a Done button and does not obscure the CTA. *(manual)*

## Verdict screen

- [ ] **AC-7**: Every judged message produces exactly one of SEND IT / REWRITE IT / SLEEP ON IT / DON'T SEND IT, plus a non-empty reason. *(`JudgmentEngineTests`)*
- [ ] **AC-8**: Verdict meaning is never conveyed by color alone — headline text and a distinct symbol are always present. *(manual + code review)*
- [ ] **AC-9**: START OVER returns to a blank input screen with no residual text. *(`JudgeViewModelTests.testResetReturnsToInputAndClearsText`)*
- [ ] **AC-10**: HELP ME REWRITE IT is present for normal verdicts and absent for safety-routed verdicts. *(manual + code review of `VerdictView`)*
- [ ] **AC-11**: The share action shares only the verdict headline and app name — never the user's original pasted text. *(code review of `VerdictView.shareText`)*
- [ ] **AC-12**: The share action is absent for safety-routed verdicts. *(manual + code review)*

## Rewrite flow

- [ ] **AC-13**: All 7 intents (Flirt, Make plans, Get clarity, Apologize, Set a boundary, Get closure, Say less) are selectable. *(`RewriteEngineTests.testEveryIntentReturnsUpToThreeNonEmptyOptions`)*
- [ ] **AC-14**: Each intent returns between 1 and 3 non-empty rewrite options. *(`RewriteEngineTests`)*
- [ ] **AC-15**: Copy writes the selected rewrite text to the system clipboard and shows a confirmation. *(`JudgeViewModelTests.testCopyWritesToClipboardAndSetsConfirmation`)*

## Safety routing

- [ ] **AC-16**: A message containing a credible threat of violence is routed to DON'T SEND IT with `isSafetyRouted == true`. *(`JudgmentEngineTests.testViolenceThreatIsSafetyRouted`)*
- [ ] **AC-17**: A message containing a self-harm statement is safety-routed. *(`JudgmentEngineTests.testSelfHarmStatementIsSafetyRouted`)*
- [ ] **AC-18**: A message containing stalking language is safety-routed. *(`JudgmentEngineTests.testStalkingLanguageIsSafetyRouted`)*
- [ ] **AC-19**: Safety-routed responses never use a joking/playful tone. *(`SafetyScannerTests`, manual copy review)*

## Data & privacy

- [ ] **AC-20**: No network request is made anywhere in the app. *(code review — no `URLSession`/networking code exists)*
- [ ] **AC-21**: The pasted message is not written to `UserDefaults`, files, or `os_log`/`print` at any point. *(code review)*
- [ ] **AC-22**: Relaunching the app after force-quit shows a blank input screen — nothing persisted. *(manual)*

## Accessibility

- [ ] **AC-23**: All interactive controls have accessibility labels and meet the 44×44pt minimum tap target. *(code review + manual VoiceOver pass)*
- [ ] **AC-24**: The app remains usable and non-clipped at the largest Dynamic Type accessibility size. *(manual)*
- [ ] **AC-25**: With Reduce Motion enabled, phase transitions are instant rather than animated. *(code review of `Theme.reduceMotionAware`, manual)*

## Resilience

- [ ] **AC-26**: Extremely long input (150+ words) is judged without crashing and produces a REWRITE IT verdict. *(`JudgmentEngineTests.testVeryLongMessageSuggestsRewrite`)*
- [ ] **AC-27**: Multiline input is judged without crashing. *(`JudgmentEngineTests.testMultilineInputIsHandled`)*
- [ ] **AC-28**: Empty/whitespace-only strings passed directly to the engine (defensive case) do not crash. *(`JudgmentEngineTests`)*

Note: because this app makes no network calls, the spec's "API success / malformed API response / timeout / offline" scenarios do not apply to this release — see `DECISIONS.md` and `AI_SAFETY.md`/`API_CONTRACT.md` for why, and what changes if a remote engine is introduced later.
