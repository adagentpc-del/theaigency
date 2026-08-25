# Release Checklist — Should I Text Him?

Mirrors the Release Gate in `DAY_01_Should_I_Text_Him_Claude_Prompt.md` and Apple Submission Baseline in `MICRO_APP_FACTORY.md` §10. Status reflects what was actually verifiable from this build environment (a Linux container with no Xcode/macOS toolchain) versus what genuinely requires a Mac.

| # | Item | Status |
|---|---|---|
| 1 | Project builds using Apple-current submission tooling | 🔲 **Not run** — no Xcode available in this environment. Code was written and manually reviewed for syntax/API correctness but never compiled. **First required action on a Mac.** |
| 2 | No hardcoded secret exists | ✅ Verified by full source review — no secrets in the codebase (there's no networking layer to hold one). |
| 3 | Core experience works | ✅ by code/logic review + unit tests covering the engine and view model. 🔲 Needs an on-device run to confirm the actual UI feels right. |
| 4 | Loading/error/offline states work | ✅ Loading state implemented and covered by `isJudging`. Error/offline states are **not applicable** — the app makes no network calls (see `DECISIONS.md`). |
| 5 | Safety routing works | ✅ Implemented and covered by `SafetyScannerTests`/`JudgmentEngineTests`. 🔲 Tests need to actually run on Apple's toolchain to be proven green. |
| 6 | Accessibility review is complete | ✅ Code-level review complete — see `ACCESSIBILITY_CHECKLIST.md`. 🔲 Manual VoiceOver/Dynamic Type/Reduce Motion device pass still required. |
| 7 | Privacy map matches code | ✅ `PRIVACY_DATA_MAP.md` was written directly from the shipped code, not aspirationally. |
| 8 | Privacy manifest/dependency requirements are checked | ✅ `PrivacyInfo.xcprivacy` present and accurate (zero tracking, zero collected data, zero required-reason APIs — matches zero-dependency, zero-persistence codebase). |
| 9 | No placeholder copy or dead controls remain | ✅ Every button in every view has a real, wired handler; no "Lorem ipsum" or TODO copy in user-facing strings. |
| 10 | App Store metadata draft exists | ✅ `APP_STORE_METADATA.md`. |
| 11 | Release checklist exists | ✅ This document. |
| 12 | Tests pass | 🔲 **Not run** — cannot execute `XCTest` without Xcode. Test files exist and were manually reviewed for correctness (`ShouldITextHimTests/`). |
| 13 | Compiler warnings eliminated where reasonable | 🔲 Cannot confirm without compiling. Code was written defensively (no force-unwraps on user data, no obvious warning patterns) but this is unverified. |
| 14 | Anything requiring founder/App Store/backend credentials is listed under FOUNDER ACTION REQUIRED | ✅ See `FOUNDER_ACTION_REQUIRED.md`. |

## What "done" still requires (from `MICRO_APP_FACTORY.md` §17)

| Item | Status |
|---|---|
| Core use case works on a physical iPhone | 🔲 Requires founder hardware |
| No known release-blocking defect | 🔲 Pending first real build |
| Security review complete | ✅ `SECURITY_REVIEW.md` |
| Privacy map complete | ✅ `PRIVACY_DATA_MAP.md` |
| Accessibility review complete | ✅ code-level; 🔲 device pass |
| Current Apple requirements checked | 🔲 Must be re-verified at submission time — Apple's requirements change |
| App Store metadata complete | ✅ draft; 🔲 screenshots need a real build |
| Screenshots complete | 🔲 Requires a running build |
| Support/privacy URLs live | 🔲 Requires founder domain/hosting action |
| TestFlight build verified | 🔲 Requires founder Apple Developer account |
| Submission sent | 🔲 |
| Launch content prepared | 🔲 Hooks drafted in `APP_STORE_METADATA.md`; actual video/content not produced |
| Portfolio tracker updated | 🔲 Founder-owned, outside this repo |

## Recommended first steps on a Mac

1. `open ShouldITextHim.xcodeproj` in current Xcode. Let Xcode auto-resolve/upgrade the project format if prompted (expected — the project file was hand-authored, see `DECISIONS.md` #5).
2. Build the `ShouldITextHim` scheme for a simulator. Fix any compiler errors — none are expected from the review, but this has not been proven.
3. Run the test suite (`Cmd+U`). All tests in `ShouldITextHimTests/` should pass; if any fail, they indicate either a logic bug or a test assumption mismatch introduced by not being able to compile-check during authoring.
4. Run on a physical iPhone. Walk the full flow: input → judge → verdict (all four kinds — try messages designed to trigger each) → rewrite flow for at least 2 intents → copy → share → start over → force-quit and relaunch.
5. Toggle VoiceOver, max Dynamic Type, and Reduce Motion and re-walk the flow.
6. Add real App Icon artwork (see `FOUNDER_ACTION_REQUIRED.md`) — the asset catalog slot exists but is empty.
7. Once green, proceed to TestFlight per Apple's current process.
