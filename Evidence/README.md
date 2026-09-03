# Evidence

Private local iOS vault for compliments, wins, screenshots, feedback, milestones, and other real-world receipts.

## Architecture
- SwiftUI, iOS 17+
- Codable/UserDefaults local persistence
- PhotosPicker for premium image attachments
- LocalAuthentication for optional device authentication
- StoreKit 2 non-consumable lifetime entitlement
- No account, backend, AI-generated affirmations, tracking, or ads

## Product rules
- Free: up to 20 text evidence entries + core resurfacing mode
- Lifetime unlock: unlimited entries, image attachments, and premium vault features
- Product ID: `com.theaigency.evidence.lifetime`
- Bundle ID: `com.theaigency.evidence`
- Resurfacing favors favorites and least-recently shown entries
- Sensitive UI is marked privacy-sensitive and can relock when the app leaves active state

## Build
Run `xcodegen generate`, then build/test the `Evidence` scheme. CI runs unit tests and a Release simulator build.

## External release setup
Create the App Store Connect record, bundle ID and non-consumable product using the exact IDs above; configure signing/team credentials and upload final screenshots. No runtime environment variables are required.
