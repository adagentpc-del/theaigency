# Start Me — Accessibility Checklist

Per `MICRO_APP_FACTORY.md` §9. Marked **Implemented** where the code
demonstrably does this, or **Needs manual verification** where it requires
VoiceOver/a simulator/a device to confirm.

## VoiceOver labels & reading order

- [x] Implemented — Home: task field has an explicit accessibility label
      ("What do you need to start?" distinct from its visual placeholder);
      the rotating example caption is `accessibilityHidden` so VoiceOver
      doesn't read a changing caption mid-interaction
      (`Features/Home/HomeView.swift`).
- [x] Implemented — Starter: the primary action text carries
      `.isHeader` so VoiceOver announces it as the screen's main content;
      reassurance text has its own identifier and is read after it in
      natural top-to-bottom order (`Features/Starter/StarterView.swift`).
- [x] Implemented — Timer: the countdown has an explicit
      `accessibilityLabel` ("N seconds remaining") instead of relying on
      VoiceOver to read "1:00" digit-by-digit (`Features/Timer/TimerView.swift`).
- [x] Implemented — Completion: the title carries `.isHeader`
      (`Features/Completion/CompletionView.swift`).
- [x] Implemented — every interactive control (buttons, toggle, links) has
      a stable `accessibilityIdentifier` from `Utilities/AccessibilityIdentifiers.swift`,
      shared between views and tests so they can't silently drift apart.
- [ ] Needs manual verification — full VoiceOver swipe-through on device
      for natural reading order end-to-end (see `RELEASE_CHECKLIST.md`).

## Dynamic Type

- [x] Implemented — All type uses `Theme.Typography`, which is built on
      `.system(_:design:)` text styles (`.largeTitle`, `.headline`,
      `.body`, `.subheadline`) that scale automatically with the user's
      preferred text size, rather than fixed point sizes. The one
      exception is the 88pt timer digits (`Theme.Typography.timer()`),
      which is a fixed size by design — a countdown needs a stable,
      glanceable size — but it never truncates because it displays at
      most 5 characters (`M:SS`).
- [x] Implemented — `HomeView`'s task input uses `.lineLimit(1...4)` so it
      grows with large text instead of clipping.
- [ ] Needs manual verification — largest Accessibility Dynamic Type
      sizes (AX5) on device, checking nothing clips or overlaps.

## Minimum tap targets

- [x] Implemented — `Theme.minimumTapTarget = 44`; `PrimaryButtonStyle`
      and `SecondaryButtonStyle` both enforce `minHeight: 44` (primary adds
      12pt more) and full-width layout where used
      (`DesignSystem/Theme.swift`).
- [ ] Needs manual verification — the Settings gear icon in the Home
      toolbar uses the system default toolbar button target size; confirm
      it meets 44×44 on device (system-provided, expected to pass, not
      independently measured here).

## Contrast & color

- [x] Implemented — All text/background colors are semantic system colors
      (`Color.primary`, `Color.secondary`, `Color(uiColor: .systemBackground)`)
      that automatically meet platform contrast guidelines in both
      appearances, plus one custom accent color
      (`Assets.xcassets/AccentColor.colorset`) with explicit light and
      dark variants, both warm/high-contrast, not a low-contrast pastel.
- [x] Implemented — No information is conveyed by color alone: the
      Starter screen's reassurance text and the Timer's completion state
      are always accompanied by text, never a color-only indicator.

## Reduce Motion

- [x] Implemented — `RootView` disables the cross-screen transition
      animation when `accessibilityReduceMotion` is on
      (`App/RootView.swift`).
- [x] Implemented — Home's rotating example captions and the Timer's
      rotating microcopy both stop rotating entirely under Reduce Motion
      rather than just removing the animation curve
      (`HomeViewModel.startRotatingPlaceholders`, `TimerView.startMicrocopyRotation`).

## VoiceOver & the timer specifically

- [x] Implemented — The countdown does **not** trigger a VoiceOver
      announcement every second; it is a normal `Text` with a label that
      VoiceOver reads only when the user explicitly navigates to it,
      never an `.accessibilityAddTraits(.updatesFrequently)` or timed
      announcement. This matches the requirement not to announce every
      second of the timer.

## Accessible text entry

- [x] Implemented — The task field is a standard SwiftUI `TextField`
      (multi-line via `axis: .vertical`), which gets full system keyboard,
      dictation, and VoiceOver text-editing support for free — no custom
      text input control was built.

## Landscape

- [x] Implemented — iPhone is portrait/portrait-upside-down only
      (`Info.plist`); iPad supports all four orientations. Layouts use
      `ScrollView`/`VStack` with no fixed absolute positioning, so they
      reflow rather than clip in the supported orientations.
- [ ] Needs manual verification — iPad landscape layout has not been
      visually inspected (no simulator available here).

## Outstanding — needs Xcode/device

- [ ] Full VoiceOver pass on a physical device across all five screens.
- [ ] Dynamic Type at AX sizes on device.
- [ ] Reduce Motion toggle confirmed live on device (logic path verified
      in code and by inspection only).
- [ ] Reduce Transparency / Increase Contrast system settings spot check
      (no reliance on translucency/blur materials in this UI, so expected
      to be unaffected, but unverified on-device).
