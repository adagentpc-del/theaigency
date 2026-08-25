# Acceptance Criteria

Each item is written to be objectively checkable on a build. Covered by an automated `XCTest` where noted; otherwise it's a manual/physical-device check (see `RELEASE_CHECKLIST.md`).

## Step 1 — Proposed message

- [ ] **AC-1**: With an empty or whitespace-only message, NEXT is disabled. *(`JudgeViewModelTests.testBlankMessageIsInvalid`, `testWhitespaceOnlyMessageIsInvalid`, `testProceedToGoalDoesNothingWithBlankMessage`)*
- [ ] **AC-2**: With any non-whitespace message, NEXT is enabled and advances to Step 2. *(`JudgeViewModelTests.testProceedToGoalAdvancesWithValidMessage`)*
- [ ] **AC-3**: No judgment occurs on Step 1 — there is no verdict-producing control on this screen. *(code review of `MessageStepView`)*
- [ ] **AC-4**: A visible Clear control appears once text is entered. *(manual)*

## Step 2 — Goal

- [ ] **AC-5**: All 7 goals are selectable (Flirt, Make plans, Get clarity, Apologize, Set a boundary, Get closure, Just checking in). *(`RewriteEngineTests.testEveryGoalReturnsUpToThreeNonEmptyOptions` exercises all 7; manual for the picker UI)*
- [ ] **AC-6**: Selecting a goal advances to Step 3 and is retained for the rest of the session (including the rewrite flow). *(`JudgeViewModelTests.testSelectGoalAdvancesToContext`, `testStartRewriteUsesGoalFromTheOriginalRequest`)*
- [ ] **AC-7**: Back returns to Step 1 without losing the previously entered message. *(`JudgeViewModelTests.testBackToMessageFromGoal`)*

## Step 3 — Context

- [ ] **AC-8**: JUDGE MY TEXT is disabled until either the pasted-conversation field is non-blank or all three quick-context questions are answered. *(`JudgeViewModelTests.testQuickContextInvalidUntilAllThreeAnswered`, `testConversationContextRequiresNonBlankText`)*
- [ ] **AC-9**: Back returns to Step 2 without losing the previously entered message or context answers already given. *(`JudgeViewModelTests.testBackToGoalFromContext`)*
- [ ] **AC-10**: The pasted-conversation option visibly states the content stays on-device. *(manual + code review of `ContextStepView`)*

## Step 4 — Judgment

- [ ] **AC-11**: Judgment (`JudgeViewModel.submitContext()`) cannot produce a verdict unless a valid message, a selected goal, and valid context all exist. *(`JudgeViewModelTests.testSubmitContextDoesNothingWithoutGoal`, `testSubmitContextDoesNothingWithoutContext`, `testSubmitContextProducesVerdictOnlyAfterAllThreeSteps`)*
- [ ] **AC-12**: Every judged request produces exactly one of SEND IT / REWRITE IT / SLEEP ON IT / DON'T SEND IT, plus a non-empty reason that references the stated goal and/or context rather than the message in isolation. *(`LocalJudgmentProviderFixtureTests`, all 34 fixtures)*
- [ ] **AC-13**: The canonical worked example from the product brief is reproduced exactly: proposed message "Hey stranger lol", goal Get clarity, context "asked a direct question 1–3 days ago, no response" → verdict DON'T SEND IT. *(`LocalJudgmentProviderFixtureTests`, fixture "Unanswered direct question (canonical example)"; also `DeterministicJudgmentRulesTests.testCanonicalUnansweredClarityQuestionReturnsDontSend`)*
- [ ] **AC-14**: The identical proposed message can produce different verdicts under different context — this is the direct regression test for the reported "defaults to SEND IT too often" defect. *(`LocalJudgmentProviderFixtureTests.testIdenticalMessageProducesDifferentVerdictsForDifferentContext`)*
- [ ] **AC-15**: Across the fixture suite, at least 3 distinct verdicts appear and SEND IT accounts for well under 60% of outcomes — the engine must not default to SEND IT as its dominant answer. *(`LocalJudgmentProviderFixtureTests.testVerdictsAreMeaningfullyDiverseAcrossFixtures`)*
- [ ] **AC-16**: Verdict meaning is never conveyed by color alone. *(manual + code review, unchanged from first release)*
- [ ] **AC-17**: START OVER returns to a blank Step 1 with every step's state cleared. *(`JudgeViewModelTests.testResetClearsEveryStepsState`)*
- [ ] **AC-18**: HELP ME REWRITE IT and the share control are present for normal verdicts and absent for safety-routed verdicts. *(manual + code review of `VerdictView`)*
- [ ] **AC-19**: The share action shares only the verdict headline and app name — never the proposed message, the pasted conversation, or the quick-context answers. *(code review of `VerdictView.shareText`)*

## Rewrite flow

- [ ] **AC-20**: Tapping HELP ME REWRITE IT does not re-ask for goal — it goes straight to rewrite options for the goal already selected in Step 2. *(`JudgeViewModelTests.testStartRewriteUsesGoalFromTheOriginalRequest`)*
- [ ] **AC-21**: Each goal returns between 1 and 3 non-empty rewrite options. *(`RewriteEngineTests`)*
- [ ] **AC-22**: Copy writes the selected rewrite text to the system clipboard and shows a confirmation. *(`JudgeViewModelTests.testCopyWritesToClipboardAndSetsConfirmation`)*

## Safety routing

- [ ] **AC-23**: A message containing a credible threat of violence, self-harm statement, coercion, or stalking language is routed to DON'T SEND IT with `isSafetyRouted == true`, regardless of goal or context. *(`LocalJudgmentProviderFixtureTests`, the 4 safety fixtures)*
- [ ] **AC-24**: The safety scan covers the proposed message, the pasted conversation, and the quick-context notes field — risky language cannot bypass routing by being placed in context instead of the message. *(`LocalJudgmentProviderFixtureTests`, "Pasted conversation — self-reported repeated contact" and the coercion fixture)*
- [ ] **AC-25**: Safety-routed responses never use a joking/playful tone. *(`SafetyScannerTests`, manual copy review)*

## Anti-harassment behavior

- [ ] **AC-26**: When the user has described (via quick-context notes or a pasted conversation) already reaching out more than once without a response, the app never nudges toward sending again. *(`LocalJudgmentProviderFixtureTests`, "Obvious harassment / repeated contact", "Repeated unanswered messages", "Pasted conversation — self-reported repeated contact"; `DeterministicJudgmentRulesTests.testRepeatedContactAlwaysWinsRegardlessOfTone`)*

## Data & privacy

- [ ] **AC-27**: No network request is made anywhere in the app, including for the new context inputs. *(code review — no `URLSession`/networking code exists)*
- [ ] **AC-28**: Neither the proposed message, the pasted conversation, nor the quick-context notes are written to `UserDefaults`, files, or logs at any point. *(code review)*
- [ ] **AC-29**: Relaunching the app after force-quit returns to a blank Step 1 — nothing persisted from any step. *(manual)*

## Accessibility

- [ ] **AC-30**: All interactive controls across all four steps have accessibility labels and meet the 44×44pt minimum tap target, including the new quick-context choice buttons and the segmented context-method picker. *(code review + manual VoiceOver pass)*
- [ ] **AC-31**: The app remains usable and non-clipped at the largest Dynamic Type accessibility size on every step, including the longer Step 3 quick-context screen. *(manual)*
- [ ] **AC-32**: With Reduce Motion enabled, phase transitions between all six phases are instant rather than animated. *(code review of `Theme.reduceMotionAware`, manual)*

## Resilience

- [ ] **AC-33**: Extremely long proposed messages (150+ words) are judged without crashing and produce REWRITE IT. *(`LocalJudgmentProviderFixtureTests`, "Extremely long emotional paragraph", "Repeated apology / groveling long message")*
- [ ] **AC-34**: A pasted conversation with no special signal is judged conservatively (REWRITE IT) rather than confidently, since the local engine does not deep-parse free text. *(`LocalJudgmentProviderFixtureTests`, "Pasted conversation — no special signal (honest fallback)")*
- [ ] **AC-35**: Empty/whitespace-only strings passed directly to `MessageSignals`/`SafetyScanner` do not crash. *(code review — same guards as the first release)*

Note: because this app makes no network calls, the spec's "API success / malformed API response / timeout / offline" scenarios do not apply to this release — see `DECISIONS.md` and `API_CONTRACT.md` for why, and what changes if a remote `JudgmentProvider` is introduced later.
