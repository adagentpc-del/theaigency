# theAIgincy Sept 3 Micro-Apps — Release Status

All three apps are local-first, account-free iOS 17+ products with one-time StoreKit 2 monetization. No backend or AI API is required.

## Keep One
- Bundle ID: `com.theaigency.keepone`
- Lifetime product: `com.theaigency.keepone.lifetime`
- Name: Keep One
- Subtitle: Declutter by Choosing Favorites
- Category: Lifestyle
- Price target: $4.99 lifetime
- Keywords: declutter,closet cleanout,minimalism,keep or toss,wardrobe,organize,decision maker
- Promotional text: Stop deciding whether something is good enough to keep. Put your stuff head-to-head, choose your favorites, and discover what you actually love.
- Screenshot order: Make your stuff compete / Keep one / Your champion / The cut list / One-time unlock

## Evidence
- Bundle ID: `com.theaigency.evidence`
- Lifetime product: `com.theaigency.evidence.lifetime`
- Name: Evidence
- Subtitle: Keep Proof of Your Wins
- Category: Lifestyle
- Price target: $4.99 lifetime
- Keywords: wins tracker,compliment journal,accomplishments,success journal,reflection,motivation
- Promotional text: Save real compliments, wins, screenshots and feedback. When you need perspective, bring receipts—not generic affirmations.
- Screenshot order: Your history not hype / Save real evidence / I Need Evidence / Private vault / Face ID lock
- Review note: The app is a private reflection/journaling utility. It does not diagnose, treat, or claim clinical mental-health outcomes.

## Kill The Loop
- Bundle ID: `com.theaigency.killtheloop`
- Lifetime product: `com.theaigency.killtheloop.lifetime`
- Name: Kill The Loop
- Subtitle: Close One Thing at a Time
- Category: Productivity
- Price target: $3.99 lifetime
- Keywords: procrastination,brain dump,to do,unfinished tasks,reminders,focus,productivity
- Promotional text: Stop staring at giant task lists. Capture what's taking up mental space, see one loop, then do it, schedule it, or deliberately kill it.
- Screenshot order: One loop one decision / Do it / Schedule it / Kill it / Zero open loops

## App Review / Privacy
- No account creation.
- No advertising SDKs.
- No tracking.
- No cloud photo or text upload.
- User-generated content remains local to the device.
- StoreKit 2 transactions are verified on-device.
- Evidence requests Photos and Face ID only when the associated feature is used.
- Keep One requests Photos only when adding contender images.
- Kill The Loop requests notifications only when scheduling/resurfacing a loop.

## External setup required before submission
1. Create the three app records in App Store Connect using the bundle IDs above.
2. Create each non-consumable lifetime in-app purchase using the exact product IDs above and target launch prices.
3. Add the Apple Developer Team/signing identity in Xcode/App Store Connect CI if automatic signing is not already available.
4. Complete tax/banking agreements if StoreKit paid apps are not already enabled on the account.
5. Upload final App Store screenshots from the built apps and complete the standard Apple privacy questionnaire using the privacy notes above.

There are no runtime environment variables or server secrets required for these three V1 apps.
