# theAIgincy Micro-App Factory
Version: 1.0
Owner: theAIgincy
Purpose: Build, validate, ship, measure, and iterate one distinct iOS micro-app per day with approximately two hours of founder involvement.

---

## 1. Mission

Build a portfolio of small, useful, entertaining, dopamine-rich iOS apps based on proven demand.

The objective is not to create 30 random apps or 30 reskins. The objective is to run 30 inexpensive product experiments and identify 1–3 apps with real organic distribution, retention, or monetization potential.

Primary short-term business target:
- Reach approximately $6,000/month in portfolio revenue.
- Prefer low operating cost.
- Prefer simple one-time monetization when appropriate.
- Launch free when distribution and learning are more valuable than immediate monetization.
- Add ads, Pro unlocks, credit packs, or annual plans only when the product economics justify them.

---

## 2. Core Portfolio Rules

Every app must have:
1. A specific user job.
2. A distinct interaction model.
3. A clear reason to exist beyond copying an existing app.
4. A recognizable visual/product identity.
5. A result or payoff delivered quickly.
6. A realistic App Store search/discovery strategy.
7. A short-form content hook that can be demonstrated in seconds.
8. Instrumentation sufficient to determine whether the app is working.

Do not:
- Ship simple reskins under different bundle IDs.
- Clone copyrighted branding, artwork, copy, proprietary content, or UI.
- Build unnecessary accounts, backends, permissions, or infrastructure.
- Add AI merely because AI is available.
- Add subscriptions to trivial utilities unless recurring value actually exists.
- Embed secrets or private API keys in the iOS client.
- Collect data that the product does not need.

---

## 3. Default Product Philosophy

Preferred loop:

OPEN -> DO ONE THING -> GET RESULT -> FEEL SOMETHING -> SHARE/RETURN

Preferred technical profile:
- Native SwiftUI.
- Local-first.
- No login by default.
- No backend by default.
- No database server by default.
- No account by default.
- No tracking by default.
- No permissions unless required for core functionality.
- No third-party dependency unless it materially reduces risk or implementation time.
- Persist locally only when persistence materially improves the product.
- Make useful behavior available immediately.

AI should only be introduced when semantic understanding or generation materially improves the product.

---

## 4. Daily Opportunity Scoring

Each candidate should be scored 1–10 on:

- Existing demand
- App Store search intent / ASO
- Social/TikTok hook
- Dopamine / emotional payoff
- Repeat-use potential
- Shareability
- Monetization potential
- Build simplicity
- Founder time required
- Operating cost
- App Review risk
- Competitive weakness / room for differentiation

Recommended weighted score:

Opportunity Score =
20% existing demand
15% searchability
15% social/viral potential
10% repeat use
10% monetization
10% competitive gap
10% implementation simplicity
5% operating cost
5% App Review / compliance risk

Do not automatically build the highest social score. The portfolio should deliberately test different demographics, use cases, and acquisition loops.

---

## 5. Monetization Decision Tree

### Zero or near-zero marginal cost
Preferred:
- Free
- $0.99–$4.99 one-time purchase
- Free + one-time Pro unlock

### AI or other meaningful variable cost
Preferred:
- Small free trial/sample
- Credit pack
- One-time usage pack
- Annual only if there is recurring value

### High organic usage
Possible later:
- Ads
- Pro unlock
- Paid feature packs
- Annual plan

Avoid weekly subscriptions for trivial utilities.

Do not delay a promising launch merely to perfect monetization.

---

## 6. App Architecture Baseline

Use:
- SwiftUI
- Current production Xcode supported by Apple submission requirements
- Current required iOS SDK or later
- async/await where appropriate
- StoreKit 2 for Apple digital purchases
- SwiftData/UserDefaults/local files when suitable
- URLSession for simple network access

Avoid by default:
- Firebase
- Supabase
- custom authentication
- account systems
- unnecessary analytics SDKs
- ad SDKs at initial launch
- remote configuration
- push notifications
- background modes
- location
- contacts
- microphone
- camera/photos
- HealthKit
- Bluetooth
- third-party login

These may be added only if core functionality requires them.

---

## 7. Security Baseline

Before release verify:

### Secrets
- No API keys, tokens, private URLs, private signing material, or credentials committed to source.
- Any secret-backed API uses an appropriate server-side proxy.
- `.gitignore` excludes local secrets/config.
- Build settings do not expose production secrets.

### Networking
- HTTPS only unless a documented exception is required.
- Validate server responses.
- Fail safely.
- Apply reasonable timeouts.
- Do not log sensitive user content.

### Local data
- Store only what is necessary.
- Use Keychain for credentials/tokens if any exist.
- Do not persist sensitive user-entered content unless the feature requires it.
- Provide deletion/reset where stored user data exists.

### Dependencies
- Minimize dependencies.
- Review permissions, SDK behavior, privacy manifests, and maintenance status.
- Remove abandoned or unnecessary packages.

### Abuse
If user-generated or AI-generated content exists:
- Define prohibited content.
- Add output safety rules.
- Add graceful refusal behavior where necessary.
- Do not make unsupported medical, legal, financial, diagnostic, or relationship-certainty claims.

---

## 8. Privacy Baseline

Every app receives its own privacy page under:

https://theAIgincy.com/apps/[slug]/privacy

and support page:

https://theAIgincy.com/apps/[slug]/support

Privacy documentation must match actual behavior.

For every release explicitly document:
- Data entered by user
- Data stored locally
- Data transmitted off-device
- Third parties receiving data
- Analytics
- Advertising
- Purchases
- Identifiers
- Retention
- Deletion process
- Permissions
- Tracking status

Never select an App Store privacy answer because it sounds preferable. Select the answer that accurately describes the shipped binary and service architecture.

Maintain a `PRIVACY_DATA_MAP.md` in each repo.

---

## 9. Accessibility Baseline

Every release must review:
- VoiceOver labels
- VoiceOver reading order
- Dynamic Type
- minimum tap targets
- sufficient contrast
- information not communicated only by color
- Reduce Motion behavior for nonessential animations
- logical focus
- accessible buttons and controls
- landscape behavior if supported
- text clipping at large accessibility sizes

Maintain `ACCESSIBILITY_CHECKLIST.md`.

---

## 10. Apple Submission Baseline

Before submission verify current Apple requirements.

At minimum:
- Built with Apple’s currently accepted Xcode/iOS SDK.
- Valid bundle identifier.
- Correct signing.
- Production-quality icon.
- Accurate app name/subtitle/description.
- Accurate screenshots showing the real app.
- Privacy Policy URL.
- Support URL.
- Accurate App Privacy answers.
- Age rating questionnaire completed.
- In-app purchases configured if applicable.
- Restore purchases where required.
- No placeholder screens/text.
- No dead buttons.
- No crashes.
- No hidden functionality.
- Review notes explain anything non-obvious.
- TestFlight build tested on physical hardware.
- Third-party SDK/privacy manifest requirements checked.
- Required-reason APIs audited where applicable.

Apple guidelines are living requirements. Re-check before every submission rather than relying indefinitely on this document.

---

## 11. Required Repo Documents

Each micro-app repo should contain:

- `/README.md`
- `/PRODUCT_SPEC.md`
- `/ACCEPTANCE_CRITERIA.md`
- `/PRIVACY_DATA_MAP.md`
- `/ACCESSIBILITY_CHECKLIST.md`
- `/SECURITY_REVIEW.md`
- `/APP_STORE_METADATA.md`
- `/RELEASE_CHECKLIST.md`
- `/DECISIONS.md`

Optional:
- `/AI_SAFETY.md`
- `/API_CONTRACT.md`
- `/ANALYTICS_PLAN.md`
- `/MONETIZATION.md`

---

## 12. Analytics Baseline

Do not add invasive analytics merely to collect data.

Minimum product events conceptually:
- app_open
- first_action_started
- first_action_completed
- result_created
- share_started
- share_completed
- paywall_seen
- purchase_started
- purchase_completed
- return_session

For apps with no analytics SDK, use App Store Connect metrics initially.

Evaluate:
- impressions
- product page views
- downloads
- conversion rate
- crashes
- retention
- sessions
- purchases
- revenue
- TikTok views
- link clicks
- user reviews

---

## 13. Daily Build Workflow

### A. 8:00 AM Opportunity Brief
Produce:
1. Top 3 current opportunities.
2. Evidence of demand.
3. Existing competitor pattern.
4. Main user complaints/gaps.
5. Recommended app.
6. Differentiator.
7. MVP.
8. Monetization.
9. TikTok/Reel hook.
10. Build-risk assessment.

### B. Founder Decision
Select one product.

Maximum founder decision time: ~15 minutes.

### C. Product Specification
Generate:
- Product promise
- Target user
- user flow
- screens
- states
- copy
- data behavior
- monetization
- edge cases
- safety
- acceptance tests

### D. Build
Claude/Codex implements the app.

### E. Automated Repair
- Build
- test
- inspect warnings
- fix
- retest
- repeat until release-quality or a blocker is documented

### F. Security/Compliance Audit
Run the established security/compliance master review against actual code.

Classify findings:
- RELEASE BLOCKER
- FIX BEFORE REVIEW
- ACCEPTABLE RISK
- POST-LAUNCH HARDENING
- NOT APPLICABLE

Fix release blockers.

### G. Physical Device QA
Founder tests:
- fresh install
- first open
- core action
- background/foreground
- offline if applicable
- purchase if applicable
- restore if applicable
- large text
- VoiceOver spot check
- light/dark mode
- interruption/relaunch
- poor network where applicable

### H. App Store Package
Prepare:
- name
- subtitle
- keywords
- description
- promotional text if useful
- category
- age rating inputs
- privacy answers
- screenshots
- icon
- support URL
- privacy URL
- review notes

### I. Submit
Upload/TestFlight -> final QA -> submit to App Review.

### J. Distribution
Publish at least one short-form demonstration:
- hook in first 1–2 seconds
- show problem
- show app
- show satisfying result
- simple CTA

### K. Record Result
Update portfolio tracker with:
- date
- app
- bundle ID
- submission status
- approval/rejection
- installs
- conversion
- retention
- revenue
- social views
- notes

---

## 14. Stop/Scale Rules

Do not spend equal effort on every app forever.

### Leave alone
If app has:
- low impressions
- low conversion
- low engagement
- no organic signal

Keep available unless there is a maintenance/compliance reason to remove it.

### Iterate
If app shows:
- above-average product page conversion
- repeat use
- reviews mentioning a specific desired feature
- organic TikTok/search traffic
- meaningful paywall interaction

Give it a focused follow-up iteration.

### Attack
If app shows breakout behavior:
- rapidly rising installs
- meaningful organic ranking/search traffic
- strong sharing
- unexpected revenue
- strong retention

Pause lower-value experiments if necessary and invest in the winner.

The goal is not “30 apps.”
The goal is to discover scalable distribution.

---

## 15. First 7 Experiments

1. Should I Text Him? — AI/dating/shareability
2. One Damn Thing — productivity/local-only
3. Fuck It, Decide — entertainment/decision utility
4. Should I Buy It? — money/humor
5. No Contact — retention/emotional utility
6. Roasty Toasty — AI/shareability/consent-first humor
7. Last Time I... — evergreen practical utility

This sequence intentionally tests different audiences and behavioral loops.

---

## 16. Day 1 Product Definition — Should I Text Him?

### Promise
Before you send the text you may regret, run it through the app.

### Core input
User pastes a message they are considering sending.

### Core output
Return one clear verdict:
- SEND IT
- REWRITE IT
- SLEEP ON IT
- DON'T SEND IT

Then provide:
- one concise reason
- optional rewrite choices based on intent

Intent choices:
- Flirt
- Make plans
- Get clarity
- Apologize
- Set a boundary
- Get closure
- Say less

### Product tone
Funny, sharp, confident, concise.

Do not:
- diagnose people
- claim certainty about another person's intent
- encourage stalking, harassment, coercion, retaliation, humiliation, or abuse
- present the tool as therapy or professional relationship counseling

### Data
Preferred:
- no account
- no long-term message history
- no persistent storage of pasted texts by default
- transmit only what is required for analysis if AI is used
- do not log raw messages in production

### Monetization
Launch path:
- free initial analyses
- simple one-time credit/unlock only if necessary to cover AI costs
- no default weekly subscription
- ads deferred

### Sharing
Allow a user to share the verdict/result without exposing the original private text unless the user explicitly chooses to include it.

### Success event
User reaches a verdict in under ~10 seconds from opening the app.

---

## 17. Definition of Done

An app is not “done” because it compiles.

Done means:
- core use case works on a physical iPhone
- no known release-blocking defect
- security review complete
- privacy map complete
- accessibility review complete
- current Apple requirements checked
- App Store metadata complete
- screenshots complete
- support/privacy URLs live
- TestFlight build verified
- submission sent
- launch content prepared
- portfolio tracker updated

---

## 18. Operating Principle

Build small.
Ship real.
Measure behavior.
Do not polish invisible things.
Do not overbuild infrastructure.
Do not confuse complexity with value.
Use each release to learn which demand, demographic, acquisition loop, interaction pattern, and monetization model actually produces results.
