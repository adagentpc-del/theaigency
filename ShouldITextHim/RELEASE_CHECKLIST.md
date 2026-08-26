# Release Checklist — Should I Text Him?

Mirrors the Release Gate in `DAY_01_Should_I_Text_Him_Claude_Prompt.md` and Apple Submission Baseline in `MICRO_APP_FACTORY.md` §10.

## Status note (second QA repair — semantic judgment architecture)

Two physical-device QA passes have now happened. The first found the engine judged messages in isolation and defaulted to SEND IT too often; that was fixed with a 3-step goal/context-aware flow. The second found that even with goal/context, a keyword-based engine couldn't recognize hostility outside its phrase list; that is fixed in this repair by making primary judgment genuinely semantic via a server-side AI proxy (`RemoteAIJudgmentProvider` + `server/`), while keeping safety routing and a few mechanical checks local and instant. **This repair, like the ones before it, was authored in a Linux container with no Xcode/macOS toolchain and has not been compiled.** The server-side TypeScript code has also never been run (no Node environment in this container either) — see `FOUNDER_ACTION_REQUIRED.md`.

| # | Item | Status |
|---|---|---|
| 1 | Project builds using Apple-current submission tooling | ✅ Confirmed by founder for the pre-repair build. 🔲 **Not yet reconfirmed** for this repair — new/changed files listed below. |
| 2 | No hardcoded secret exists | ✅ Verified by full source review — the client has no API key anywhere; the server holds `ANTHROPIC_API_KEY` only as a Vercel environment variable, never committed (`server/.gitignore` excludes `.env`). |
| 3 | Core experience works | ✅ by code/logic review + expanded test suite. 🔲 Needs an on-device run against a real deployed server. |
| 4 | Loading/error/offline states work | ✅ Now genuinely exercised — loading state on Step 3, and a distinct offline/error fallback state on the verdict screen (`localFallbackBanner` + retry) when the AI is unavailable. 🔲 Needs a manual test with the device in Airplane Mode. |
| 5 | Safety routing works | ✅ Unchanged mechanism, still fully local and instant regardless of network. Covered by `SafetyScannerTests` + safety fixtures. 🔲 Needs to actually run on Apple's toolchain. |
| 5b | **Judgment-quality regression (both prior QA defects)** | ✅ `LocalJudgmentProviderFixtureTests`, `DeterministicJudgmentRulesTests`, and `AdversarialSemanticFixtureTests` (60 adversarial fixtures across 15 categories) cover both defects, including the exact profanity regression. 🔲 Needs to actually run on Apple's toolchain — hand-traced against the implementation, not compiler-verified. |
| 5c | **Live semantic judgment quality** | 🔲 **Not verified** — no live server exists yet in this environment. `RemoteAIJudgmentProviderLiveTests.swift` is ready to run against a real deployed endpoint (set `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT`) once `server/` is deployed. This is the only thing that can actually prove the AI's judgment quality, as opposed to the client's plumbing. |
| 6 | Accessibility review is complete | ✅ Code-level review covers the new offline-fallback banner and retry button. 🔲 Manual VoiceOver/Dynamic Type/Reduce Motion device pass still required. |
| 7 | Privacy map matches code | ✅ `PRIVACY_DATA_MAP.md` rewritten for the new reality: user content now leaves the device when semantic judgment runs. This is a **material change** from the previous release's "zero network calls" claim — do not reuse old marketing/App Store copy that says nothing leaves the device. |
| 8 | Privacy manifest/dependency requirements are checked | ✅ `PrivacyInfo.xcprivacy` updated to declare User Content collection (not linked to identity, not used for tracking, App Functionality purpose). |
| 9 | No placeholder copy or dead controls remain | ✅ Every control wired. ⚠️ `RemoteAIJudgmentProvider.defaultEndpoint` is a **placeholder URL** (`https://should-i-text-him.example.com/api/judge`) — this is a real release blocker, not just copy, until replaced with the deployed server's actual URL. See `FOUNDER_ACTION_REQUIRED.md`. |
| 10 | App Store metadata draft exists | ✅ `APP_STORE_METADATA.md` — App Review notes and privacy claims updated to match the new network behavior. |
| 11 | Release checklist exists | ✅ This document. |
| 12 | Tests pass | 🔲 **Not run** — cannot execute `XCTest` without Xcode. Test suite now spans 10 files including new provider/mock/adversarial-fixture tests, all hand-traced against the implementation during authoring. |
| 13 | Compiler warnings eliminated where reasonable | 🔲 Cannot confirm without compiling — this now also includes the TypeScript server (`cd server && npm install && npm run build`, not run in this environment). |
| 14 | Anything requiring founder/App Store/backend credentials is listed under FOUNDER ACTION REQUIRED | ✅ See `FOUNDER_ACTION_REQUIRED.md` — now includes deploying the server and obtaining an Anthropic API key. |

## What changed in this repair

- **New primary judgment path**: `RemoteAIJudgmentProvider` (client) + `server/` (TypeScript/Vercel proxy calling `claude-opus-5`). See `API_CONTRACT.md`.
- **`JudgmentResult` gained three fields**: `recommendedAction`, `rewriteOptions`, `isLocalFallback`.
- **`DeterministicJudgmentRules` lost four rules** (calm boundary/apology/closure → send, positive reciprocity → send) — no local rule can produce SEND IT any more.
- **`FallbackJudgment` always returns REWRITE IT** — the previous "no red flags → SEND IT" branches are gone.
- **`VerdictView`** gained an offline-fallback banner + retry button, and a goal-aware rewrite-button label (`recommendedAction == .direct`).
- **`JudgeViewModel`** defaults to `RemoteAIJudgmentProvider` instead of `LocalJudgmentProvider`, and gained `retryJudgment()`.
- **Test suite** grew from 5 files to 10: new `RemoteAIJudgmentProviderTests`, `MockURLProtocol`, `AdversarialSemanticFixtures`, `AdversarialSemanticFixtureTests`, `RemoteAIJudgmentProviderLiveTests`; `LocalJudgmentProviderFixtureTests` and `DeterministicJudgmentRulesTests` updated for the never-sends invariant.
- **New `server/` directory** — a self-contained TypeScript project, not part of the iOS app target, deployed separately.
- **Privacy posture changed materially**: this is the first release where user content leaves the device in normal operation. `PRIVACY_DATA_MAP.md`, `PrivacyInfo.xcprivacy`, and `APP_STORE_METADATA.md` were all updated accordingly — re-verify the App Store Privacy questionnaire reflects this before submission.

## Recommended first steps on a Mac (and one on any machine with Node)

1. **Deploy the server first** (see `server/README.md`) — get a real Anthropic API key, deploy to Vercel, note the endpoint URL.
2. **Update `RemoteAIJudgmentProvider.defaultEndpoint`** in the Swift source to that real URL.
3. Open `ShouldITextHim.xcodeproj` in current Xcode, build the `ShouldITextHim` scheme, fix any compiler errors.
4. Run the test suite (`Cmd+U`). Everything except `RemoteAIJudgmentProviderLiveTests` should run with no network/credentials needed. To also run the live suite, set `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` to your deployed URL on the test scheme and re-run — treat any failures there as real prompt/model-quality signal, not a test to loosen.
5. Run on a physical iPhone against the real deployed server. Walk the full 4-step flow with: the exact profanity regression case; a genuinely healthy message (calm apology, mutual flirting); a safety-routed example; and — with the device in Airplane Mode — confirm the offline-fallback banner and retry button work.
6. Toggle VoiceOver, max Dynamic Type, and Reduce Motion and re-walk the flow, including the new offline banner.
7. Add real App Icon artwork (still outstanding from the first release).
8. Re-verify the App Store Privacy questionnaire against the updated `PRIVACY_DATA_MAP.md` — this app's privacy posture changed materially in this repair.
9. Once green, proceed to TestFlight per Apple's current process.
