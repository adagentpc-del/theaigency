# Start Me — Security Review

Reviewed against `MICRO_APP_FACTORY.md` §7. This review was performed by
static code review only — no Xcode toolchain, simulator, or physical
device was available in this build environment. Items requiring a real
build are marked accordingly.

## Secrets

- **No API keys, tokens, or credentials in source.** `grep -rniE
  "api[_-]?key|secret|token|password" StartMe/ StartMeTests/` returns no
  matches other than identifier names like `A11yID` / test method names —
  confirmed by manual read of every source file during authoring.
- No `.xcconfig.local`, `.env`, or `Secrets.swift` file exists; the root
  `.gitignore` excludes all of these patterns defensively for every app in
  the monorepo, including this one.
- No server-side proxy exists or is needed — Start Me has no networked
  feature.

## Networking

- **Zero networking code.** No `URLSession`, `URLRequest`, `URLComponents`
  used for network calls, or `WKWebView`/`SFSafariViewController` embedded
  browsing anywhere in `StartMe/`. The only URLs in the app
  (`https://theAIgincy.com/apps/start-me/privacy` and `/support` in
  `Features/Settings/SettingsView.swift`) are opened via `Link`, which
  hands off to the system browser — the app itself never fetches them.
- No HTTP allowed — moot, since there are no network calls to secure.
- No sensitive content is ever logged: there are no `print`/`os_log`/
  `NSLog` calls anywhere in the app target that touch user-entered task
  text.

## Local data

- Only aggregate integers (per-day start counts, a continuation counter)
  and one boolean (haptics preference) are persisted, all via
  `UserDefaults` — see `docs/PRIVACY_DATA_MAP.md` for the exact keys.
- No Keychain usage — there is nothing credential-shaped to store.
- Task text is never persisted (see `PRIVACY_DATA_MAP.md`); it lives only
  in `@Published` SwiftUI state for the duration of one flow through
  Home → Starter → Timer, and is discarded on return to Home.
- **Settings > Clear Local Data** provides a complete, working deletion
  path for every persisted key (`StatsStore.clearAllData()`), covered by
  `StatsStoreTests.test_clearAllData_resetsEverything`.

## Dependencies

- **Zero third-party dependencies.** No Swift Package Manager packages, no
  CocoaPods `Podfile`, no Carthage `Cartfile`. The project file
  (`StartMe.xcodeproj/project.pbxproj`) contains no `XCRemoteSwiftPackageReference`
  or `XCSwiftPackageProductDependency` entries. Everything is
  SwiftUI/Foundation/UIKit (for `UIImpactFeedbackGenerator` /
  `UINotificationFeedbackGenerator` haptics only) and `XCTest`.
- Nothing to review for privacy manifests, abandoned packages, or
  maintenance status, because there is nothing external.

## Abuse / generated content

- Start Me does not generate free-form AI content — every possible output
  string is one of a small, hand-authored, hand-reviewed set in
  `Engine/StarterActionLibrary.swift` plus one templated fallback sentence
  built from the user's own words (`TaskStarterEngine.fallbackObjectPhrase`).
  There is no possibility of the app itself generating unsafe, defamatory,
  or otherwise harmful text.
- User-entered text is routed through `Engine/SafetyRouter.swift` before
  ever being used to select or template an action — see `docs/SAFETY.md`.
- The app makes no medical, legal, financial, diagnostic, or
  relationship-certainty claims (verified by reading every user-facing
  string in `Features/`).

## Build configuration

- Debug builds enable `DEBUG=1` and disable optimization
  (`SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)"`); Release
  builds do not define `DEBUG` and use standard Swift optimization —
  standard Xcode-generated behavior, unmodified.
- No debug-only UI, test menus, or backdoors exist in `Features/` that
  would need to be stripped for Release — there was never a debug affordance
  added in the first place.
- `ITSAppUsesNonExemptEncryption` is `false` in `Info.plist` — accurate,
  since Start Me uses no encryption beyond what iOS provides by default
  and performs no networking.

## Outstanding — needs Xcode/device

- [ ] Run `xcodebuild -scanBuildForAnalysis`/Xcode's static analyzer —
      unavailable in this environment (no Xcode toolchain on this Linux
      build host). The warning-level Clang/Swift analyzer flags in
      `project.pbxproj`'s build settings match the sibling
      `ShouldITextHim` project's proven configuration, but have not been
      run against this codebase.
- [ ] Confirm no secrets are captured in a TestFlight/App Store Connect
      build log at archive time (founder action, at submission).
