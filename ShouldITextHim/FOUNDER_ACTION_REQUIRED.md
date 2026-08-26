# Founder Action Required — Should I Text Him?

Everything here needs your credentials, hardware, domain access, or a business decision — none of it can be completed autonomously in this build environment.

## 1. Provision self-hosted inference infrastructure and pick a model via the benchmark *(blocker, new)*

Your instruction was explicit: no Anthropic/OpenAI/paid hosted LLM provider for production judgment — a **self-hosted local language model** instead. This cannot be faked or skipped:

- Provision a machine (or use existing infrastructure) capable of running a small local language model — a GPU is strongly recommended for acceptable latency, though llama.cpp/Ollama can run CPU-only more slowly.
- Install [llama.cpp server](https://github.com/ggml-org/llama.cpp) or [Ollama](https://ollama.com) on it.
- **Run the benchmark harness** (`cd server && npm install && npm run benchmark -- --model <candidate> --base-url <your-inference-server-url>`) against every candidate model you're considering (`qwen3:8b`, `qwen3:4b`, `llama3.2:3b`, or others available to you). This could not be run in this build environment — there is no GPU/inference server here. **Do not deploy a model that hasn't cleared the documented threshold** (`server/README.md` → "Model benchmark harness": ≥95% acceptable verdict rate, zero critical safety failures, zero SEND IT false positives on hostile fixtures, <1% malformed responses). Do not pick the fastest or largest model by default — pick the smallest one that clears the threshold.
- Deploy `server/` (Docker Compose example provided, or bare-metal/systemd) configured with the winning model — full instructions in `server/README.md`. There is no API key to obtain from any third party for this step.
- **Update `RemoteAIJudgmentProvider.defaultEndpoint`** in `ShouldITextHim/Engine/RemoteAIJudgmentProvider.swift` from its current placeholder (`https://should-i-text-him.example.com/api/judge`) to your real deployed URL. The app will not produce real AI judgments until this is done.
- Put a reverse proxy/TLS terminator in front of the deployed API, and confirm your inference server (llama.cpp/Ollama) is **not** reachable from outside your private network — see `server/README.md` → "Security."

## 2. Build & test on a real Apple toolchain *(blocker)*

This repair, like the ones before it, was authored in a Linux container with no Xcode/macOS available, so the iOS side has **not been compiled**. Every file was written and manually reviewed for correctness, and 60 adversarial fixtures plus the exact profanity regression were hand-traced against the implementation. (The server side, unlike prior rounds, *was* verified in this environment — Node is available here, so `npm install`/`npm run build` were actually run, and the built server was actually started and exercised against real HTTP requests, including its rate limiter and production-mode safety guard. See `SECURITY_REVIEW.md` and `RELEASE_CHECKLIST.md` for exactly what was run.) For the iOS side:
- Pull this commit, open `ShouldITextHim.xcodeproj` in current Xcode, and build the `ShouldITextHim` scheme.
- Run the test suite (`Cmd+U`) — this now includes `RemoteAIJudgmentProviderTests` (network mocked, no real server needed), covering the new `need_context`/`add_context` mapping, and `AdversarialSemanticFixtureTests`. `RemoteAIJudgmentProviderLiveTests` will skip unless you set `SHOULDITEXTHIM_LIVE_JUDGE_ENDPOINT` to your deployed server — do that once step 1 is done, and treat any failures there as a real signal about prompt/model quality (see `server/src/lib/prompt.ts`), not something to work around.
- This is the single most important next step — see `RELEASE_CHECKLIST.md`.

## 3. Physical-device QA of the AI-backed flow *(blocker)*

Requires your iPhone and a deployed server with a benchmarked model (step 1). Walk the full 4-step flow with several goal/context combinations — specifically the exact scenario from your second QA report ("hello gangster..." style hostility with no matching keyword), a genuinely healthy message (calm apology, mutual flirting) to confirm the model still says SEND IT when appropriate, a case with too little context to confirm NEED MORE CONTEXT and the ADD MORE CONTEXT button work correctly, and a safety-sensitive example. **Also test with the device in Airplane Mode** to confirm the offline-fallback banner and "Try again" button work and never present a degraded local guess as a real judgment. Then repeat with VoiceOver on, Dynamic Type maxed, and Reduce Motion on. Checklist in `RELEASE_CHECKLIST.md` → "Recommended first steps."

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

Both are placeholders per the Factory standard, and this app's privacy posture **changed materially** starting with the second QA repair — it is no longer "nothing ever leaves your phone." The live privacy page must accurately describe that the proposed message, goal, and context are sent to your own server, which processes them using your own self-hosted local model — no third party is involved — per the updated `PRIVACY_DATA_MAP.md`. Do not publish or reuse privacy copy written for the fully-offline version, and do not describe a named third-party AI provider — there isn't one.

## 7. App Store Connect listing

- Create the app record, enter the metadata from `APP_STORE_METADATA.md` (review/adjust the description, keywords, and especially the age-rating questionnaire answers — flagged in that document as needing your judgment call on Apple's current wording).
- Capture real screenshots from a running build per the shot list in `APP_STORE_METADATA.md`.
- **Complete the App Privacy questionnaire using the updated `PRIVACY_DATA_MAP.md`** — "User Content" is now collected (transmitted for processing, not linked to identity, not used for tracking). Do not answer "No data collected" — that was accurate for the previous release and is no longer accurate.
- Set the final primary/secondary category (Lifestyle recommended).

## 8. Business decisions (non-blocking for v1, but yours to make)

- Whether to launch fully free (current build) or fast-follow with the one-time-unlock StoreKit 2 product described in `POST_LAUNCH.md`. There's no per-request third-party API bill any more (the model is self-hosted), but you do carry the fixed/ongoing cost of the inference hardware itself — see `server/README.md` → "Cost."
- Whether to invest in stronger abuse mitigation for the server (a distributed rate-limit store, Apple DeviceCheck/App Attest) before or shortly after launch — see `server/README.md` → "Known limitations" and `POST_LAUNCH.md`. Not a launch blocker: there's no per-request third-party API bill to run up any more (the model is self-hosted), but a bad actor could still exhaust your own inference hardware's capacity or degrade latency for everyone else.
- Launch content (TikTok/Reels) per the hooks drafted in `APP_STORE_METADATA.md` — actual filming/editing is outside this repo.
- Portfolio tracker entry per `MICRO_APP_FACTORY.md` §13.K — owned by you outside this repo.

## 9. Final submission

Once the above are complete: final QA pass on the TestFlight build, then submit to App Review. Re-check Apple's current submission requirements at that time — `MICRO_APP_FACTORY.md` §10 explicitly notes these are living requirements, not something this document can freeze in time.
