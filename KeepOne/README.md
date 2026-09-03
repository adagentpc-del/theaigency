# Keep One

Local-first iOS decluttering game: photograph contenders, make head-to-head choices, and rank what the user genuinely prefers.

## Architecture
- SwiftUI, iOS 17+
- App-private Application Support persistence for battle state/history
- PhotosPicker with on-device image normalization before persistence
- StoreKit 2 non-consumable lifetime entitlement
- No account, backend, AI API, tracking, or ads

## Product rules
- First battle free, maximum 8 contenders
- Lifetime unlock: unlimited battles and up to 64 contenders
- Product ID: `com.theaigency.keepone.lifetime`
- Bundle ID: `com.theaigency.keepone`
- Pairing engine limits comparisons while avoiding duplicate pairs
- Every choice records winner/loser IDs so Undo is exact
- Cut-list items can be marked Sell, Donate, Keep Anyway, or Undecided

## UX/accessibility
- System typography and controls support Dynamic Type and standard iOS tap targets
- Core controls have VoiceOver labels
- Light/Dark Mode are inherited from system semantic colors
- No essential information depends on animation

## Build
Run `xcodegen generate`, then build/test the `KeepOne` scheme. CI runs unit tests and a Release simulator build.

## External release setup
Create the App Store Connect record, register the bundle ID, create the non-consumable StoreKit product using the exact ID above, assign signing/team credentials, and upload final screenshots. No runtime environment variables are required.
