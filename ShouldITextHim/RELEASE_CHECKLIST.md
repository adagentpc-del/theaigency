# Release Checklist — Should I Text Him?

Mirrors the Release Gate in `DAY_01_Should_I_Text_Him_Claude_Prompt.md` and Apple Submission Baseline in `MICRO_APP_FACTORY.md` §10.

## Status note (post-QA repair)

The founder confirmed the **first build** compiled and ran in a real iOS Simulator, and physical-device QA on that build surfaced the judgment-logic defect this repair fixes. This repair was authored the same way the first build was — in a Linux container with no Xcode/macOS toolchain — so **the new/changed files in this repair have not yet been compiled or run**, even though the project structure and settings that already proved they build were left untouched. Everything below is scoped accordingly.

| # | Item | Status |
|---|---|---|
| 1 | Project builds using Apple-current submission tooling | ✅ Confirmed by founder for the pre-repair build. 🔲 **Not yet reconfirmed** for this repair's new files (`Goal.swift`, `QuickContext.swift`, `ContextInput.swift`, `JudgmentRequest.swift`, `MessageSignals.swift`, `ContextSignals.swift`, `DeterministicJudgmentRules.swift`, `FallbackJudgment.swift`, `JudgmentProvider.swift`, `LocalJudgmentProvider.swift`, `ClipboardWriting.swift`, `MessageStepView.swift`, `GoalStepView.swift`, `ContextStepView.swift`, updated `JudgeViewModel.swift`/`VerdictView.swift`/`RewriteResultView.swift`/`RootView.swift`/`RewriteEngine.swift`). **First required action on a Mac.** |
| 2 | No hardcoded secret exists | ✅ Verified by full source review — still no networking layer, still no secrets. |
| 3 | Core experience works | ✅ by code/logic review + expanded test suite (34 product fixtures + rule/view-model unit tests). 🔲 Needs an on-device run of the new 4-step flow. |
| 4 | Loading/error/offline states work | ✅ Loading state moved to Step 3 (`ContextStepView`), covered by `isJudging`. Error/offline still not applicable — zero network calls. |
| 5 | Safety routing works | ✅ Unchanged mechanism, now scans all three free-text inputs (message, pasted conversation, quick-context notes) — see `AI_SAFETY.md`. Covered by `SafetyScannerTests` + 4 safety fixtures in `LocalJudgmentProviderFixtureTests`. 🔲 Needs to actually run on Apple's toolchain. |
| 5b | **Judgment-quality regression (the reason for this repair)** | ✅ `LocalJudgmentProviderFixtureTests` — 34 product QA fixtures covering every category the founder specified, the canonical worked example reproduced exactly, an explicit identical-message/different-context contrast pair, and a diversity assertion that SEND IT cannot dominate outcomes. 🔲 Needs to actually run on Apple's toolchain to be proven green — hand-traced against the implementation during authoring, not compiler-verified. |
| 6 | Accessibility review is complete | ✅ Code-level review extended to the three new step views — see `ACCESSIBILITY_CHECKLIST.md`. 🔲 Manual VoiceOver/Dynamic Type/Reduce Motion device pass still required, now across 4 steps instead of 2. |
| 7 | Privacy map matches code | ✅ `PRIVACY_DATA_MAP.md` updated for the new context inputs (pasted conversation, quick-context answers) — still zero network, zero persistence. |
| 8 | Privacy manifest/dependency requirements are checked | ✅ `PrivacyInfo.xcprivacy` unchanged and still accurate — no new required-reason API usage was introduced by this repair. |
| 9 | No placeholder copy or dead controls remain | ✅ Every control across all four steps has a real, wired handler. |
| 10 | App Store metadata draft exists | ✅ `APP_STORE_METADATA.md` (screenshot shot list should be revisited to include the new goal/context steps — noted in `POST_LAUNCH.md` follow-up, not a blocker). |
| 11 | Release checklist exists | ✅ This document. |
| 12 | Tests pass | 🔲 **Not run** — cannot execute `XCTest` without Xcode. 39 total tests across 5 files (`SafetyScannerTests`, `DeterministicJudgmentRulesTests`, `LocalJudgmentProviderFixtureTests`, `RewriteEngineTests`, `JudgeViewModelTests`), all hand-traced against the implementation during authoring. |
| 13 | Compiler warnings eliminated where reasonable | 🔲 Cannot confirm without compiling. |
| 14 | Anything requiring founder/App Store/backend credentials is listed under FOUNDER ACTION REQUIRED | ✅ See `FOUNDER_ACTION_REQUIRED.md`. |

## What changed since the last confirmed-working build

- Judgment now requires message + goal + context before it runs at all (previously: message alone). See `PRODUCT_SPEC.md` and `DECISIONS.md`.
- `Intent` was renamed to `Goal` and gained a 7th case (`checkingIn` replacing `sayLess`) and lost the now-redundant post-verdict re-ask screen (`RewriteIntentView` removed).
- The judgment engine was split from one file (`JudgmentEngine.swift`, removed) into a layered architecture (`SafetyScanner`, `MessageSignals`, `ContextSignals`, `DeterministicJudgmentRules`, `FallbackJudgment`, composed by `LocalJudgmentProvider` behind a new `JudgmentProvider` protocol).
- New models: `QuickContext`, `ContextInput`, `JudgmentRequest`.
- New views: `MessageStepView` (replaces `InputView`), `GoalStepView`, `ContextStepView`.
- `VerdictView` and `RewriteResultView` now take a `JudgmentRequest`/`Goal` instead of a bare `JudgmentResult`/`Intent`, and `RootView`'s phase switch has 6 cases instead of 5.
- Test suite grew from 4 files to 5, with the new `LocalJudgmentProviderFixtureTests` adding 34 end-to-end product scenarios plus diversity/regression assertions, and `DeterministicJudgmentRulesTests` added for the rule layer specifically.

## Recommended first steps on a Mac

1. Pull this repair's commit and open `ShouldITextHim.xcodeproj` in current Xcode (same project you already confirmed opens and builds).
2. Build the `ShouldITextHim` scheme. Fix any compiler errors — none are expected from the review, but this repair's new files have not been proven to compile.
3. Run the test suite (`Cmd+U`). Pay particular attention to `LocalJudgmentProviderFixtureTests` — if any fixture fails, treat it as a real product-quality signal, not a test to loosen, per the founder's explicit instruction not to accept a provider that returns SEND IT for most scenarios.
4. Run on a physical iPhone. Walk the full 4-step flow multiple times with different goal/context combinations, specifically including: the canonical "Hey stranger lol" / Get clarity / unanswered-question example from the product brief; a case with positive reciprocity; a case with a long silence; and a safety-routed example. Confirm the reason text visibly references the goal/context, not just the message.
5. Toggle VoiceOver, max Dynamic Type, and Reduce Motion and re-walk the flow — pay particular attention to the new Step 3 quick-context picker buttons and the segmented context-method control.
6. Add real App Icon artwork (still outstanding from the first release — see `FOUNDER_ACTION_REQUIRED.md`).
7. Once green, proceed to TestFlight per Apple's current process.
