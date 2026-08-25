# Should I Text Him?

A tiny, sharp-tongued SwiftUI iPhone app: paste a text you're about to send, get an instant verdict — **SEND IT**, **REWRITE IT**, **SLEEP ON IT**, or **DON'T SEND IT** — plus an optional rewrite.

Built as App #1 of theAIgincy's 30-Day Micro-App Factory. Governing standards live in [`MICRO_APP_FACTORY.md`](MICRO_APP_FACTORY.md); the product brief lives in [`DAY_01_Should_I_Text_Him_Claude_Prompt.md`](DAY_01_Should_I_Text_Him_Claude_Prompt.md).

## What it does

1. Paste (or type) the message you're considering sending.
2. Tap **JUDGE MY TEXT**.
3. Get a verdict and a one-line reason.
4. Optionally tap **HELP ME REWRITE IT**, pick what you're actually trying to do, and get up to 3 ready-to-copy rewrites.
5. Share the verdict (never the original message) or start over.

That's the whole app. No accounts, no backend, no ads, no subscriptions.

## How judging works

The verdict is produced by a deterministic, on-device rule engine (`Engine/JudgmentEngine.swift`), not a network call to a hosted AI model. See [`DECISIONS.md`](DECISIONS.md) for why, and [`AI_SAFETY.md`](AI_SAFETY.md) for the safety-routing rules layered on top of it. This means:

- The message you paste never leaves your phone.
- There is no API key, secret, or backend to configure.
- The app works fully offline.

## Project layout

```
ShouldITextHim/
├── ShouldITextHim.xcodeproj/        Xcode project (app target + unit test target)
├── ShouldITextHim/                  App source
│   ├── ShouldITextHimApp.swift      App entry point
│   ├── Models/                      Verdict, Intent, JudgmentResult
│   ├── Engine/                      JudgmentEngine, SafetyScanner, RewriteEngine
│   ├── ViewModels/                  JudgeViewModel (all app state/flow)
│   ├── Views/                       InputView, VerdictView, RewriteIntentView, RewriteResultView, RootView
│   ├── Support/                     Theme, Haptics
│   ├── Assets.xcassets/             App icon slot + accent color
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
└── ShouldITextHimTests/             XCTest unit tests for the engine and view model
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
