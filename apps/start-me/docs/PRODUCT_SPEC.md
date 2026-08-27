# Start Me — Product Spec

Status: V1 build complete (unverified on physical hardware/Xcode — see `RELEASE_CHECKLIST.md`)
Governed by: `/MICRO_APP_FACTORY.md` (repo root — currently mirrored at `/ShouldITextHim/MICRO_APP_FACTORY.md`; see `DECISIONS.md`)

## 1. Core promise

The user knows what they need to do. They just cannot make themselves start.
Start Me gives them the smallest possible physical first action and gets
them moving for 60 seconds.

## 2. Core loop

```
TYPE THE THING
  -> GET ONE TINY PHYSICAL ACTION
  -> 60-SECOND START
  -> STOP / KEEP GOING / DONE
  -> SMALL DOPAMINE HIT
```

The product succeeds if it breaks task-initiation friction. **Do not plan
the task. Start the task.** This rule governs every feature decision below.

## 3. What Start Me is not

Not a to-do list, planner, calendar, ADHD treatment app, habit tracker,
Pomodoro system, project-management system, life coach, chatbot,
motivational-quote app, AI assistant, or productivity dashboard. If a
feature doesn't directly improve "I'm stuck -> I physically started," it
goes in `POST_LAUNCH.md`, not V1.

## 4. Target user

People experiencing task paralysis, procrastinators, overwhelmed users,
ADHD/executive-function audiences, students, professionals, people stuck on
mundane household/admin tasks.

Allowed language: overwhelmed, stuck, procrastinating, trouble starting,
task paralysis, focus, momentum. Never: treats ADHD, treats executive
dysfunction, diagnoses anything, replaces therapy, replaces medical care.

## 5. Architecture (V1)

100% local. SwiftUI + Foundation + `UserDefaults` + `XCTest`. No network
calls anywhere in the app target. No OpenAI/Anthropic/Ollama/hosted or
local LLMs, no Firebase/Supabase, no authentication, no cloud databases, no
backend. See `SECURITY_REVIEW.md` and `PRIVACY_DATA_MAP.md`.

```
apps/start-me/
├── StartMe.xcodeproj/
├── StartMe/
│   ├── App/                 StartMeApp, RootView, AppCoordinator (the whole
│   │                        app is one linear flow: home -> starter ->
│   │                        timer -> completion -> home; no nav stack)
│   ├── Models/               AppScreen, CompletionContext, TimerSession
│   ├── Engine/                TaskCategory, StarterAction, StarterActionLibrary,
│   │                          TaskStarterEngine, SafetyRouter
│   ├── Persistence/          StatsStore (UserDefaults, aggregate counts only),
│   │                          SettingsStore (haptics preference)
│   ├── DesignSystem/          Theme, Haptics
│   ├── Utilities/             DateProviding, AccessibilityIdentifiers
│   ├── Features/
│   │   ├── Home/  Starter/  Timer/  Completion/  Stats/  Settings/
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
├── StartMeTests/              XCTest unit tests + 79 classification fixtures
└── docs/                      this directory
```

## 6. Home screen

- Headline: "What do you need to start?"
- Subcopy: "Don't give me the whole plan. Just tell me the thing."
- Input placeholder: "I need to..." with a small rotating "e.g. clean my
  kitchen" caption cycling through 8 examples every 3.5s (paused under
  Reduce Motion).
- Primary CTA "START ME", disabled while the trimmed input is empty.
- No account creation, no onboarding carousel, no questionnaire, no
  category picker before entry — the user reaches the core value
  immediately.
- A small, no-shame stats line at the bottom (see §10).

## 7. Task Starter Engine

`Engine/TaskStarterEngine.swift`. Turns free-form text into one tiny
action, smaller than the task, generally completable in well under 30
seconds:

- `clean my entire apartment` -> "Throw away one piece of trash."
- `go to the gym` -> "Put your shoes on."
- `answer my emails` -> "Open your inbox."
- `file my taxes` -> "Open the website or folder you use for your taxes."
- `finish the Johnson thing` (unknown) -> "Open whatever you need to work
  on the Johnson thing. Don't finish it. Just open it."

Classification (`classify(_:)`) is a compact, substring-based router over
17 categories (`Engine/TaskCategory.swift`): cleaning, laundry, dishes,
studying, writing, email, admin, taxes, workout, leavingHouse, packing,
cooking, errands, phoneCall, organizing, computerWork, personalCare, and a
`general` fallback. It is deliberately not a brittle keyword tree — see the
code comments in `TaskStarterEngine.swift` for the ordered rule list and
`docs/DECISIONS.md` for the edge cases that shaped it (e.g. "run errands"
must not be classified as a workout).

Each category has 3–4 hand-written variants in
`Engine/StarterActionLibrary.swift`. The first variant is the canonical,
deterministic action for that category (what a first-time user sees); the
rest back "Give me a different start."

## 8. Starter screen

- Small label "Your only job:" then the action in large type.
- Reassurance line under it (e.g. "You do not have to go to the gym yet.").
- Primary CTA "START 60 SECONDS".
- Secondary controls: "Make it even smaller" (2 further reduction levels
  per variant, hidden once exhausted — never an error state) and "Give me
  a different start" (rotates to another variant in the same category,
  avoiding an immediate repeat).

## 9. Timer

60-second initial timer, 5-minute "Keep going" continuation. Countdown is
computed from elapsed wall-clock time against a fixed `startDate`
(`Features/Timer/TimerViewModel.swift`), not decremented tick-by-tick, so
it stays accurate through view updates and short foreground/background
interruptions (`refreshFromWallClock()` is called on `scenePhase == .active`).
Subtle haptics at start and completion, gated by Settings > Haptics.
Rotating microcopy ("Just this.", "You already started.", …) is skipped
under Reduce Motion.

At zero: "You started." / "That was the whole point." — KEEP GOING (starts
a 5-minute continuation), I'M DONE, I STOPPED. All three of DONE/STOPPED
return home with identical framing; stopping is never treated as failure.
Continuation completion asks "Still going?" with ANOTHER 5 / DONE.

## 10. Stats

`Persistence/StatsStore.swift` persists only aggregate, local counters —
never task text: a per-day start count (7-day rolling window), a lifetime
total, and a "continued beyond 60 seconds" count. Home shows one line like
"You started 4 things today." or "17 starts this week."; with no recent
activity it shows "You came back. That counts." — never a "you lost your
streak" message. See `docs/PRIVACY_DATA_MAP.md`.

## 11. Settings

Haptics on/off, Clear Local Data (with confirmation), Privacy Policy link,
Support link, About. Deliberately small — no theming, no account, no
customization system.

## 12. Safety

`Engine/SafetyRouter.swift` is a small deterministic keyword scan that
runs before any input is turned into an actionable step. See
`docs/SAFETY.md`.

## 13. Monetization

Free in V1. See `docs/MONETIZATION.md`.
