# Security Review — Should I Text Him?

Reviewed against the checklist in `MICRO_APP_FACTORY.md` §7 and the Day 1 spec's Security section. Classifications: **RELEASE BLOCKER**, **FIX BEFORE REVIEW**, **ACCEPTABLE RISK**, **POST-LAUNCH HARDENING**, **NOT APPLICABLE**.

## Embedded secrets

**Finding:** None found. `grep`-level review of every source file confirms no API keys, tokens, or credentials anywhere in the codebase. There is no `.xcconfig` carrying secrets and no networking layer that would need one.
**Classification:** NOT APPLICABLE (no secret-backed API exists in this release).

## Sensitive logging

**Finding:** The codebase contains no `print`, `os_log`, `NSLog`, or debugger-only logging of the user's pasted message anywhere in `JudgmentEngine`, `SafetyScanner`, `RewriteEngine`, or `JudgeViewModel`. The message only ever exists as a local variable/property, never serialized to a log sink.
**Classification:** NOT APPLICABLE — nothing to fix, confirmed by code review.

## Insecure networking

**Finding:** No networking code exists (no `URLSession`, no third-party HTTP client). There is nothing to secure because nothing is transmitted.
**Classification:** NOT APPLICABLE for this release. **POST-LAUNCH HARDENING** item recorded in `API_CONTRACT.md`/`POST_LAUNCH.md`: if a remote judgment service is added later, it must be HTTPS-only, validate/bound all responses, apply timeouts, and never log raw message content server-side.

## Overly broad permissions

**Finding:** `Info.plist` requests zero permissions (no camera, microphone, contacts, location, photos, notifications). `PrivacyInfo.xcprivacy` declares no tracking and no required-reason API usage, matching the code.
**Classification:** NOT APPLICABLE — confirmed minimal by design.

## Unsafe local persistence

**Finding:** The app writes nothing to disk, `UserDefaults`, Keychain, or any cache. There is no persistence layer to audit.
**Classification:** NOT APPLICABLE.

## Dependency risk

**Finding:** Zero third-party dependencies — no Swift Package Manager packages, no CocoaPods, no Carthage. The entire app is first-party Swift/SwiftUI/Foundation/UIKit(system).
**Classification:** NOT APPLICABLE — no dependency surface exists.

## Injection / unsafe rendering

**Finding:** All user-entered text is rendered exclusively through native SwiftUI `Text`/`TextEditor` views, which do not interpret HTML, Markdown, or any markup by default — there is no `WKWebView`, no HTML rendering, and no string interpolation into a shell/SQL/URL context anywhere in the app. The pasted message is never used to construct a file path, URL, or command.
**Classification:** NOT APPLICABLE.

## Model-output validation

**Finding:** `JudgmentEngine.judge(_:)` returns a strongly-typed `JudgmentResult` (an `enum`/`struct`-backed value, not free-form text parsed at the UI layer), so there is no untrusted "model output" string being parsed or rendered as markup. `Verdict` is a closed `enum`; `RiskFlag` is a closed `enum`; `reason` is a fixed, first-party string chosen from a small set of hardcoded copy strings in the engine itself — never generated from the user's input verbatim. Rewrite options come from a fixed template dictionary (`RewriteEngine`), not from parsing the user's message.
**Classification:** NOT APPLICABLE for this release. If a real AI backend is introduced later, its JSON response **must** be decoded into the same strongly-typed `JudgmentResult`/`RiskFlag`/`Verdict` types with a `Codable` decode that fails closed (falls back to a safe default) on any malformed or out-of-enum value — this constraint is documented in `API_CONTRACT.md` as a requirement for that future work, not a gap in this release.

## Unbounded network requests

**Finding:** Not applicable — no network requests exist.
**Classification:** NOT APPLICABLE.

## Crash / error leakage

**Finding:** The engine has no force-unwraps (`!`) on user-derived data and no `try!`/`fatalError` paths reachable from user input. Empty and whitespace-only strings are handled explicitly (`JudgmentEngineTests.testEmptyInputDoesNotCrashAndReturnsAResult`, `testWhitespaceOnlyInputDoesNotCrash`). Very long input (150+ words) and multiline input are covered by tests and do not special-case in a way that could crash.
**Classification:** ACCEPTABLE RISK — covered by unit tests; final confirmation requires running the test suite on Apple's toolchain (this container has no Xcode — see `RELEASE_CHECKLIST.md`).

## Abuse — AI/user-generated content

**Finding:** The app both consumes user-generated content (the pasted message) and generates content back (verdict reason, rewrite suggestions). `AI_SAFETY.md` documents the full rule set: a deterministic keyword/pattern scan (`SafetyScanner`) routes threats of violence, self-harm, coercion, stalking, sexual exploitation, and abuse-indicator language away from the normal witty copy into a calm, non-escalating, non-joking response, and hides the rewrite/share actions for those results so the app never helps polish or amplify risky content. The app makes no medical, legal, financial, or diagnostic claims about the user or the other person (`PRODUCT_SPEC.md` §Tone).
**Classification:** FIX BEFORE REVIEW → **RESOLVED** in this build (see `AI_SAFETY.md` for the specifics and `SafetyScannerTests`/`JudgmentEngineTests` for coverage). Pattern-list moderation is inherently incomplete; ongoing refinement is tracked as **POST-LAUNCH HARDENING** in `POST_LAUNCH.md`.

## Summary

No RELEASE BLOCKER findings remain open. The dominant reason this review is short is architectural: shipping with zero backend, zero network, zero third-party SDKs, and zero persistence eliminates entire classes of risk (secret leakage, transport security, dependency supply-chain, unbounded requests) rather than mitigating them after the fact — see `DECISIONS.md`.

**Open item requiring founder/Apple-toolchain action:** static code review cannot substitute for compiling and running the test suite with Xcode. This is listed under `FOUNDER_ACTION_REQUIRED.md`.
