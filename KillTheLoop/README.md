# Kill The Loop

Local-first iOS productivity micro-app that shows one unresolved item at a time and forces a clean resolution: do it, schedule it, or deliberately kill it.

## Architecture
- SwiftUI, iOS 17+
- Codable/UserDefaults local persistence for small text-only state
- UserNotifications for scheduled resurfacing with privacy-safe notification text
- StoreKit 2 non-consumable lifetime entitlement
- No account, backend, AI API, tracking, ads, projects, kanban boards, or giant default task list

## Product rules
- Free: up to 10 active loops
- Lifetime unlock: unlimited active loops and premium history/future features
- Product ID: `com.theaigency.killtheloop.lifetime`
- Bundle ID: `com.theaigency.killtheloop`
- Do It opens an optional 5/10/15-minute action boundary or no-timer mode; the app only marks a loop complete when the user confirms Done
- Scheduled loops move out of the active queue and return when due
- Notification previews never include the user's loop text

## UX/accessibility
- One loop dominates the main screen; the rest of the queue is intentionally hidden
- System typography and controls support Dynamic Type and standard iOS tap targets
- Destructive Kill action requires confirmation
- Light/Dark Mode use semantic system colors

## Build
Run `xcodegen generate`, then build/test the `KillTheLoop` scheme. CI runs unit tests and a Release simulator build.

## External release setup
Create the App Store Connect record, bundle ID and non-consumable product using the exact IDs above; configure signing/team credentials and upload final screenshots. No runtime environment variables are required.
