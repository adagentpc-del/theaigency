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

Judgment only ever runs after all three inputs exist — see [`PRODUCT_SPEC.md`](PRODUCT_SPEC.md) for why a 3-step flow replaced the original single-message design. No accounts, no ads, no subscriptions.

## How judging works

Three physical-device QA passes reshaped this — see [`DECISIONS.md`](DECISIONS.md) for the full history. Judgment is layered:

1. **Safety rules** (`Engine/SafetyScanner.swift`) — always run first, fully on-device, over every piece of free text you entered. Never depends on the network.
2. **Deterministic mechanical rules** (`Engine/MessageSignals.swift`, `Engine/ContextSignals.swift`, `Engine/DeterministicJudgmentRules.swift`) — structural facts (repeated contact, double-texting, breakup topic, message length) an ordered rule list can resolve confidently without needing to understand tone. Also fully on-device. **Never returns SEND IT** — see [`AI_SAFETY.md`](AI_SAFETY.md) for why.
3. **Semantic judgment** (`Engine/RemoteAIJudgmentProvider.swift`) — the primary path for everything else: hostility, sarcasm, passive aggression, manipulation, and whether the message actually fits the stated goal. Calls theAIgincy's own application API (`server/`), which prompts a **self-hosted local language model** (no third-party AI provider) and returns a short, structured, schema-validated result — including a fifth possible verdict, `NEED MORE CONTEXT`, for when there simply isn't enough to go on. **No hosted-provider or local-inference secret is ever in this app** — the server holds any such credential, and the app only ever knows the server's public URL.
4. **Conservative fallback** (`Engine/FallbackJudgment.swift`) — used only when the network/AI is unavailable. Always local, always REWRITE IT, never SEND IT — the app never fakes confidence when it can't get a real judgment.

This means:

- Safety-flagged and repeated-contact messages never leave your phone.
- Everything else is sent only to theAIgincy's own application API to get a verdict — never stored, never shown to anyone else, and never sent to any third party. See [`PRIVACY_DATA_MAP.md`](PRIVACY_DATA_MAP.md) for the full data map.
- If you're offline or the AI is unreachable, you still get a conservative, clearly-labeled result instead of a dead end.
- If the model doesn't have enough context to judge responsibly, it says so (`NEED MORE CONTEXT`) instead of guessing — see [`AI_SAFETY.md`](AI_SAFETY.md).

## Project layout

```
ShouldITextHim/
├── ShouldITextHim.xcodeproj/        Xcode project (app target + unit test target)
├── ShouldITextHim/                  App source
│   ├── ShouldITextHimApp.swift      App entry point
│   ├── Models/                      Verdict, Goal, QuickContext, ContextInput, JudgmentRequest, JudgmentResult
│   ├── Engine/                      SafetyScanner, MessageSignals, ContextSignals, DeterministicJudgmentRules,
│   │                                FallbackJudgment, JudgmentProvider, LocalJudgmentProvider,
│   │                                RemoteAIJudgmentProvider, RewriteEngine
│   ├── ViewModels/                  JudgeViewModel (all app state/flow), ClipboardWriting
│   ├── Views/                       MessageStepView, GoalStepView, ContextStepView, VerdictView,
│   │                                RewriteResultView, RootView
│   ├── Support/                     Theme, Haptics
│   ├── Assets.xcassets/             App icon slot + accent color
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
├── ShouldITextHimTests/             XCTest unit tests: deterministic-rule fixtures, safety, 60-scenario
│                                    adversarial semantic fixture suite, and mocked/live provider tests
└── server/                          Application API (TypeScript/Node/Express) — talks privately to a
                                     self-hosted local language model, deployed separately, see below
```

## Requirements

- Xcode (current version supported by Apple for App Store submission)
- iOS 17.0+ deployment target
- No third-party dependencies in the iOS app, no Swift Package Manager packages
- A deployed instance of `server/` (see `server/README.md`) — talking to a self-hosted local inference server (llama.cpp server or Ollama) running a model that has cleared `server/scripts/benchmark.ts`'s documented threshold — for real AI judgments. The app still builds and runs without one, but judgment falls back to a conservative local-only result until `RemoteAIJudgmentProvider.defaultEndpoint` points at a real deployed server.

## Building

Open `ShouldITextHim.xcodeproj` in Xcode and run the `ShouldITextHim` scheme on a simulator or device. No API keys or secrets belong in the iOS project at all — there is no third-party hosted-AI provider anywhere in this project; see `server/README.md` for where the self-hosted model configuration lives (server-side only).

## Testing

Run the `ShouldITextHim` scheme's test action (`Cmd+U`), or:

```
xcodebuild test \
  -project ShouldITextHim.xcodeproj \
  -scheme ShouldITextHim \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Everything runs with zero network access or credentials except `RemoteAIJudgmentProviderLiveTests`, which skips unless `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` is set to a real deployed server (see `AI_SAFETY.md` and `server/README.md`).

For the server, `cd server && npm install && npm run build` type-checks and compiles the whole project (application code and the benchmark script); `npm run benchmark -- --model <name> --base-url <url>` runs the 60-fixture model benchmark against a configured local model.

> This repository was built in a Linux container with no Xcode/macOS toolchain available, so `xcodebuild`/`swiftc` could not be run here — the iOS side is unverified by any compiler in this environment. Node **is** available here, so the server side is materially better verified: `npm install`/`npm run build` were actually run (clean), and the built server was actually started and exercised over real HTTP requests (validation, rate limiting, the production-mode safety guard, and inference-unavailable fallback all behaved as documented) — see `SECURITY_REVIEW.md`. No local model has been benchmarked against a real inference server in this environment (no GPU/inference server here). See [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) and [`FOUNDER_ACTION_REQUIRED.md`](FOUNDER_ACTION_REQUIRED.md) for what still needs to happen on a Mac (for iOS) and on real inference hardware (for the model benchmark) before submission.

## Documents

| Doc | Purpose |
|---|---|
| `PRODUCT_SPEC.md` | Full product/UX spec |
| `ACCEPTANCE_CRITERIA.md` | Testable pass/fail criteria |
| `PRIVACY_DATA_MAP.md` | Exactly what data goes where |
| `ACCESSIBILITY_CHECKLIST.md` | VoiceOver, Dynamic Type, Reduce Motion, contrast |
| `SECURITY_REVIEW.md` | Code-level security review results |
| `AI_SAFETY.md` | Safety routing, repeated-contact guarding, and semantic judgment architecture |
| `API_CONTRACT.md` | The `JudgmentProvider` contract and how the server-side proxy fulfills it |
| `server/README.md` | Deploying and configuring the judgment server |
| `APP_STORE_METADATA.md` | App Store listing draft |
| `RELEASE_CHECKLIST.md` | Release gate checklist |
| `DECISIONS.md` | Key engineering decisions and rationale |
| `POST_LAUNCH.md` | Deferred nice-to-haves |
| `FOUNDER_ACTION_REQUIRED.md` | Everything that needs founder credentials/hardware/decisions |
