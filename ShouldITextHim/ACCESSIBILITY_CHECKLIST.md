# Accessibility Checklist — Should I Text Him?

Status legend: ✅ implemented in code · 🔲 needs physical-device/simulator verification (see `RELEASE_CHECKLIST.md`).

## VoiceOver

- ✅ Message text field has an explicit `accessibilityLabel` ("Message to judge") and `accessibilityHint`.
- ✅ Placeholder text is `accessibilityHidden` so VoiceOver doesn't announce it as real content over the empty field.
- ✅ JUDGE MY TEXT button has a state-aware label ("Judge my text" / "Judging your text") and a hint explaining why it's disabled when input is invalid.
- ✅ Verdict headline uses a full-sentence `accessibilityLabel` ("Verdict: Send it.") instead of relying on the terse visual copy ("SEND IT.") or the SF Symbol, which is `accessibilityHidden`.
- ✅ Screen titles (app name, intent prompt, rewrite header) are marked `.isHeader` for VoiceOver rotor navigation.
- ✅ Copy buttons are labeled "Copy this rewrite"; a live "Copied to clipboard" confirmation is exposed via `.updatesFrequently`.
- ✅ Share button has an explicit label and a hint clarifying it does not include the original message.
- ✅ (Step 3, added in the judgment-flow repair) Each quick-context choice button (who texted last / time since / did he respond) has an explicit `accessibilityLabel` and toggles the `.isSelected` trait so VoiceOver announces the current answer, not just the option text. The context-method segmented picker has an explicit label.
- 🔲 Manual VoiceOver sweep on-device: confirm reading order top-to-bottom on every screen (now 4 steps instead of 2), confirm no unlabeled controls, confirm double-tap activates every control.

## Dynamic Type

- ✅ All text uses system font styles (`.largeTitle`, `.body`, `.title2`, `.title3`, etc.), which scale automatically with the user's Dynamic Type setting — no fixed point sizes for user-facing copy except the oversized verdict headline, which is capped visually but wrapped with `.multilineTextAlignment(.center)` rather than truncated.
- ✅ Verdict, rewrite, and intent lists are inside `ScrollView`s so content that grows past the screen at large accessibility sizes scrolls instead of clipping.
- 🔲 Manual check at the largest accessibility text size (Settings → Accessibility → Display & Text Size → Larger Text → max, plus the separate "Larger Accessibility Sizes" toggle): confirm no text is truncated or overlapping, confirm buttons remain tappable.

## Tap targets

- ✅ Every primary/secondary button explicitly sets `minHeight: Theme.minimumTapTarget` (44pt), matching Apple's minimum recommended hit target.

## Contrast

- ✅ Verdict colors (green/orange/blue/red) are drawn from system semantic colors, which are contrast-adjusted for light/dark mode automatically.
- ✅ Body and secondary text use `.primary`/`.secondary`/`.tertiary` semantic colors rather than hardcoded RGB values, so they track system contrast and Increase Contrast settings.
- 🔲 Manual spot-check with Increase Contrast enabled.

## Non-color-only state communication

- ✅ Every verdict pairs its color with a headline string and a distinct SF Symbol (see `PRODUCT_SPEC.md` table) — color is never the sole signal.
- ✅ Loading state is communicated via a `ProgressView` + text ("Reading the room…"), not just a color/opacity change.

## Reduce Motion

- ✅ `Theme.reduceMotionAware(_:value:)` checks `UIAccessibility.isReduceMotionEnabled` and skips the animation entirely (rather than substituting a smaller one) for all phase transitions in `RootView`.
- ✅ No animation is required to understand any state — every screen communicates its state through static text/symbols as well.
- 🔲 Manual check with Reduce Motion enabled: confirm screen changes are instant with no residual motion.

## Focus & reading order

- ✅ Views are built as simple top-to-bottom `VStack`s matching visual order, so VoiceOver's default reading order matches the visual layout without custom sort-priority hacks.
- 🔲 Manual on-device confirmation.

## Landscape

The app supports landscape on iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) and portrait-only on iPhone (see `Info.plist`), matching the single-column layout's design. No landscape-specific layout issues are expected since all screens use scrollable, flexible stacks rather than fixed geometry — 🔲 manual iPad landscape check recommended before submission if iPad support is kept.

## Outstanding manual QA

All 🔲 items above require a physical device or Simulator + VoiceOver, which this build environment (a Linux container with no Xcode) cannot perform. They are listed as required steps in `RELEASE_CHECKLIST.md` and `FOUNDER_ACTION_REQUIRED.md`.
