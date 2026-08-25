# Should I Text Him?

A tiny, sharp-tongued SwiftUI iPhone app: describe a text you're about to send, what you're trying to accomplish, and what happened before it — get an instant verdict — **SEND IT**, **REWRITE IT**, **SLEEP ON IT**, or **DON'T SEND IT** — plus an optional rewrite.

Built as App #1 of theAIgincy's 30-Day Micro-App Factory. Governing standards live in [`MICRO_APP_FACTORY.md`](MICRO_APP_FACTORY.md); the product brief lives in [`DAY_01_Should_I_Text_Him_Claude_Prompt.md`](DAY_01_Should_I_Text_Him_Claude_Prompt.md).

## What it does

1. **Step 1** — Paste (or type) the message you're considering sending. Tap **NEXT**.
2. **Step 2** — Pick what you're actually trying to accomplish (flirt, make plans, get clarity, apologize, set a boundary, get closure, or just checking in).
3. **Step 3** — Say what happened before this: either paste the recent conversation, or answer three quick questions (who texted last, how long ago, did they respond).
4. Tap **JUDGE MY TEXT** and get a verdict with a reason that references your goal and context — not just the message.
5. Optionally tap **HELP ME REWRITE IT** for up to 3 ready-to-copy rewrites (using the goal from Step 2 — you're never asked twice).
6. Share the verdict (never the original message or context) or start over.

Judgment only ever runs after all three inputs exist — see [`PRODUCT_SPEC.md`](PRODUCT_SPEC.md) for why a 3-step flow replaced the original single-message design. That's still the whole app: no accounts, no backend, no ads, no subscriptions.

## How judging works

The verdict is produced by a deterministic, on-device engine, not a network call to a hosted AI model. It's layered (see [`DECISIONS.md`](DECISIONS.md) for the full rationale):

1. **Safety rules** (`Engine/SafetyScanner.swift`) — always run first, over every piece of free text you entered.
2. **Deterministic obvious judgment** (`Engine/MessageSignals.swift`, `Engine/ContextSignals.swift`, `Engine/DeterministicJudgmentRules.swift`) — an ordered rule list combining your goal, the message's tone, and the context you gave.
3. **Conservative fallback** (`Engine/FallbackJudgment.swift`) — used only when no rule confidently applies; the seam a future AI-backed provider would occupy (see [`API_CONTRACT.md`](API_CONTRACT.md)).

All three are composed by `Engine/LocalJudgmentProvider.swift`, which conforms to a small `JudgmentProvider` protocol so a future `RemoteAIJudgmentProvider` could be swapped in without touching the UI. This means:

- Nothing you type ever leaves your phone.
- There is no API key, secret, or backend to configure.
- The app works fully offline.

## Project layout

```
ShouldITextHim/
├── ShouldITextHim.xcodeproj/        Xcode project (app target + unit test target)
├── ShouldITextHim/                  App source
│   ├── ShouldITextHimApp.swift      App entry point
│   ├── Models/                      Verdict, Goal, QuickContext, ContextInput, JudgmentRequest, JudgmentResult
│   ├── Engine/                      SafetyScanner, MessageSignals, ContextSignals, DeterministicJudgmentRules,
│   │                                FallbackJudgment, JudgmentProvider, LocalJudgmentProvider, RewriteEngine
│   ├── ViewModels/                  JudgeViewModel (all app state/flow), ClipboardWriting
│   ├── Views/                       MessageStepView, GoalStepView, ContextStepView, VerdictView,
│   │                                RewriteResultView, RootView
│   ├── Support/                     Theme, Haptics
│   ├── Assets.xcassets/             App icon slot + accent color
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
└── ShouldITextHimTests/             XCTest unit tests, including a 34-scenario product QA fixture suite
    (LocalJudgmentProviderFixtureTests.swift)
```

## Requirements

- Xcode (current version supported by Apple for App Store submission)
- iOS 17.0+ deployment target
- No third-party dependencies, no Swift Package Manager packages

## Building

Open `ShouldITextHim.xcodeproj` in Xcode and run the `ShouldITextHim` scheme on a simulator or device. There is nothing to configure — no API keys, no `.xcconfig` secrets, no environment setup.

## Testing

Run the `ShouldITextHim` scheme's test action (`Cmd+U`), or:

```
xcodebuild test \
  -project ShouldITextHim.xcodeproj \
  -scheme ShouldITextHim \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

> This repository was built in a Linux container with no Xcode/macOS toolchain available, so `xcodebuild`/`swiftc` could not be run here. See [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) and [`FOUNDER_ACTION_REQUIRED.md`](FOUNDER_ACTION_REQUIRED.md) for what still needs to happen on a Mac before submission.

## Documents

| Doc | Purpose |
|---|---|
| `PRODUCT_SPEC.md` | Full product/UX spec |
| `ACCEPTANCE_CRITERIA.md` | Testable pass/fail criteria |
| `PRIVACY_DATA_MAP.md` | Exactly what data goes where |
| `ACCESSIBILITY_CHECKLIST.md` | VoiceOver, Dynamic Type, Reduce Motion, contrast |
| `SECURITY_REVIEW.md` | Code-level security review results |
| `AI_SAFETY.md` | Safety-routing rules for high-risk content |
| `API_CONTRACT.md` | The structured judgment contract, and how to swap in a real backend later |
| `APP_STORE_METADATA.md` | App Store listing draft |
| `RELEASE_CHECKLIST.md` | Release gate checklist |
| `DECISIONS.md` | Key engineering decisions and rationale |
| `POST_LAUNCH.md` | Deferred nice-to-haves |
| `FOUNDER_ACTION_REQUIRED.md` | Everything that needs founder credentials/hardware/decisions |
