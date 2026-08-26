# Founder Action Required — Should I Text Him?

Everything here needs your credentials, hardware, domain access, or a business decision — none of it can be completed autonomously in this build environment.

## 1. Deploy the judgment server and get an Anthropic API key *(blocker, new)*

Your second QA pass found that the fully local, keyword-based engine couldn't judge hostility outside a fixed phrase list. The fix requires a real AI model, which requires a real deployed server — this cannot be faked or skipped:

- Get an Anthropic API key from [console.anthropic.com](https://console.anthropic.com) if you don't already have one.
- Deploy `server/` to Vercel (or another Node-compatible host) — full step-by-step instructions in `server/README.md`. This takes about 10 minutes with the Vercel CLI.
- Set `ANTHROPIC_API_KEY` as an encrypted environment variable in your hosting provider's dashboard — never in a committed file.
- **Update `RemoteAIJudgmentProvider.defaultEndpoint`** in `ShouldITextHim/Engine/RemoteAIJudgmentProvider.swift` from its current placeholder (`https://should-i-text-him.example.com/api/judge`) to your real deployed URL. The app will not produce real AI judgments until this is done.

## 2. Build & test on a real Apple toolchain *(blocker)*

This repair, like the ones before it, was authored in a Linux container with no Xcode/macOS available, so it has **not been compiled**. Every file was written and manually reviewed for correctness, and 60 adversarial fixtures plus the exact profanity regression were hand-traced against the implementation, but:
- Pull this commit, open `ShouldITextHim.xcodeproj` in current Xcode, and build the `ShouldITextHim` scheme.
- Run the test suite (`Cmd+U`) — this now includes `RemoteAIJudgmentProviderTests` (network mocked, no real server needed) and `AdversarialSemanticFixtureTests`. `RemoteAIJudgmentProviderLiveTests` will skip unless you set `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` to your deployed server — do that once step 1 is done, and treat any failures there as a real signal about prompt/model quality (see `server/lib/prompt.ts`), not something to work around.
- This is the single most important next step — see `RELEASE_CHECKLIST.md`.

## 3. Physical-device QA of the AI-backed flow *(blocker)*

Requires your iPhone and a deployed server (step 1). Walk the full 4-step flow with several goal/context combinations — specifically the exact scenario from your second QA report ("hello gangster..." style hostility with no matching keyword), plus a genuinely healthy message (calm apology, mutual flirting) to confirm the AI still says SEND IT when appropriate, plus a safety-sensitive example. **Also test with the device in Airplane Mode** to confirm the offline-fallback banner and "Try again" button work and never present a degraded local guess as a real judgment. Then repeat with VoiceOver on, Dynamic Type maxed, and Reduce Motion on. Checklist in `RELEASE_CHECKLIST.md` → "Recommended first steps."

## 4. App icon artwork

`Assets.xcassets/AppIcon.appiconset/` has a correctly configured single-size (1024×1024) icon slot but **no actual image** — generating real brand/visual identity is a design decision, not something to fabricate as a placeholder. Apple requires a production-quality icon before submission.

## 5. Apple Developer account setup

- Bundle identifier used in this build: `com.theaigincy.shoulditexthim` (test target: `com.theaigincy.shoulditexthim.tests`) — confirm this matches your App Store Connect / Apple Developer team, or change it and re-sign.
- Code signing is currently set to `Automatic` — requires your Apple Developer Program membership and team selection in Xcode.
- TestFlight build upload and internal testing.

## 6. Live privacy & support URLs — content must reflect the new architecture

`PRIVACY_DATA_MAP.md`/`APP_STORE_METADATA.md` reference:
- `https://theAIgincy.com/apps/should-i-text-him/privacy`
- `https://theAIgincy.com/apps/should-i-text-him/support`

Both are placeholders per the Factory standard, and this app's privacy posture **changed materially** in this repair — it is no longer "nothing ever leaves your phone." The live privacy page must accurately describe that the proposed message, goal, and context are sent to your server (and from there to Anthropic) to obtain a judgment, per the updated `PRIVACY_DATA_MAP.md`. Do not publish or reuse privacy copy written for the fully-offline version.

## 7. App Store Connect listing

- Create the app record, enter the metadata from `APP_STORE_METADATA.md` (review/adjust the description, keywords, and especially the age-rating questionnaire answers — flagged in that document as needing your judgment call on Apple's current wording).
- Capture real screenshots from a running build per the shot list in `APP_STORE_METADATA.md`.
- **Complete the App Privacy questionnaire using the updated `PRIVACY_DATA_MAP.md`** — "User Content" is now collected (transmitted for processing, not linked to identity, not used for tracking). Do not answer "No data collected" — that was accurate for the previous release and is no longer accurate.
- Set the final primary/secondary category (Lifestyle recommended).

## 8. Business decisions (non-blocking for v1, but yours to make)

- Whether to launch fully free (current build) or fast-follow with the one-time-unlock StoreKit 2 product described in `POST_LAUNCH.md`. Note this app now has a real per-request AI cost (unlike the fully-local previous version), which may accelerate the case for monetization or a usage cap — see `server/README.md` → "Cost."
- Whether to invest in stronger abuse mitigation for the server (rate limiting, Apple DeviceCheck/App Attest) before or shortly after launch — see `server/README.md` → "Known limitation: abuse mitigation" and `POST_LAUNCH.md`. Not a launch blocker, but the current endpoint has no protection against a bad actor hammering it and running up your Anthropic bill.
- Launch content (TikTok/Reels) per the hooks drafted in `APP_STORE_METADATA.md` — actual filming/editing is outside this repo.
- Portfolio tracker entry per `MICRO_APP_FACTORY.md` §13.K — owned by you outside this repo.

## 9. Final submission

Once the above are complete: final QA pass on the TestFlight build, then submit to App Review. Re-check Apple's current submission requirements at that time — `MICRO_APP_FACTORY.md` §10 explicitly notes these are living requirements, not something this document can freeze in time.
