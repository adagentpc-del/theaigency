# Keep One

Local-first iOS decluttering game: photograph contenders, make head-to-head choices, and rank what the user genuinely prefers.

## Architecture
- SwiftUI, iOS 17+
- JSON/Codable persistence in UserDefaults for battle state and history
- PhotosPicker for on-device image selection
- StoreKit 2 non-consumable lifetime entitlement
- No account, backend, AI API, tracking, or ads

## Product rules
- First battle free, maximum 8 contenders
- Lifetime unlock: unlimited battles and up to 64 contenders
- Product ID: `com.theaigency.keepone.lifetime`
- Bundle ID: `com.theaigency.keepone`
- Pairing engine limits comparisons while avoiding duplicate pairs
- Every choice records winner/loser IDs so Undo is exact

## Build
Run `xcodegen generate`, then build/test the `KeepOne` scheme. CI runs unit tests and a Release simulator build.

## External release setup
Create the App Store Connect record, register the bundle ID, create the non-consumable StoreKit product using the exact ID above, assign signing/team credentials, and upload final screenshots. No runtime environment variables are required.
