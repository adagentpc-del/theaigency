# Decisions — Should I Text Him?

Key engineering/product decisions and the reasoning behind them, so future iteration doesn't relitigate settled tradeoffs without cause.

## Revision note (post-QA repair)

Physical-device QA on the first build found a release-blocking defect: `JudgmentEngine` judged the pasted message in isolation and defaulted to SEND IT for far too many materially different situations, because it had no way to know the user's goal or what had happened before the message. Decisions 7–12 below describe the redesign that fixed this. Decisions 1–6 (from the original build) still hold and are unchanged in spirit; where the redesign touches them, that's called out explicitly.

---

## 1. Local deterministic judgment engine instead of a hosted AI model

**Decision:** Judgment is on-device Swift logic, not a call to a hosted model. *(Unchanged by the redesign — see decision 7 for how the on-device logic itself changed.)*

**Why:** The Day 1 spec is explicit: never place a model API key in the client, and if no approved secure backend exists, build a deterministic local fallback and mark the server connection as an explicit release blocker rather than faking a production AI connection. This repo started empty with no existing backend/proxy pattern to reuse, and standing one up is a business/infrastructure decision outside what a build session can make on the founder's behalf. See `API_CONTRACT.md` for the exact seam a future backend would occupy.

## 2. No accounts, no persistence, no analytics

**Decision:** Unchanged. Still true after the redesign, and still true even though there are now three input steps' worth of state (proposed message, goal, context) instead of one — all of it lives only in `JudgeViewModel`'s in-memory properties and is discarded on START OVER or process death.

## 3. No monetization in v1

**Decision:** Unchanged.

## 4. Simple text-based share instead of a rendered image share card

**Decision:** Unchanged. The share text still contains only the verdict headline and app name — never the proposed message, the pasted conversation, or the quick-context answers.

## 5. Hand-authored `.xcodeproj`

**Decision:** Unchanged approach; regenerated for the new/removed/renamed files in this repair (see the file list at the end of this document's revision history in `RELEASE_CHECKLIST.md`).

## 6. Environment constraint: no Xcode/macOS toolchain in this build environment

**Fact, not a choice:** Still true. Every file in this repair was hand-reviewed for correctness but not compiled by this session. Physical builds since the first release have confirmed the project itself compiles and runs; the newly added files in this repair have not yet been confirmed on Apple's toolchain — see `RELEASE_CHECKLIST.md`.

---

## 7. Three-layer judgment architecture: safety → deterministic rules → fallback

**Decision:** `LocalJudgmentProvider` composes three distinct layers instead of one flat scoring function:

1. **Deterministic safety rules** (`SafetyScanner`, unchanged from the first release) — always run first, over every piece of free text the user provided (proposed message, pasted conversation, and quick-context notes), and always win if triggered.
2. **Deterministic obvious judgment** (`MessageSignals` + `ContextSignals` + `DeterministicJudgmentRules`) — an ordered, priority-based rule list that reasons about the user's **goal** and **context** together with the message's tone. This is new; the first release only had message-tone scoring.
3. **Conservative, context-aware fallback** (`FallbackJudgment`) — used only when no rule in layer 2 confidently applies. This is the layer that used to default to SEND IT unconditionally; it now differentiates based on context (see decision 9).

**Why:** The reported defect was really an architectural problem, not a missing keyword. Bolting more keywords onto a single scoring function would have kept the same failure mode (message judged in isolation) while making the code harder to reason about. Splitting "is this text dangerous," "is this an obvious case given what the user told us," and "we're genuinely unsure" into separate, individually testable layers makes each layer's job small and auditable, and gives a clean seam for a future `RemoteAIJudgmentProvider` to occupy layer 3 without touching layers 1–2 or the UI (see `API_CONTRACT.md`).

## 8. `JudgmentProvider` protocol abstraction

**Decision:** `JudgeViewModel` depends on a `JudgmentProvider` protocol (`func judge(_ request: JudgmentRequest) async -> JudgmentResult`), not on `LocalJudgmentProvider` directly. `LocalJudgmentProvider` is the only conformance today.

**Why:** This is the mechanism that satisfies the requirement to support a secure AI judgment provider later without embedding an API key in the client or rewriting the UI/ViewModel. A future `RemoteAIJudgmentProvider` would call theAIgincy's own server-side proxy (which holds any model credential) and conform to the exact same protocol; swapping it in is a one-line dependency-injection change in `JudgeViewModel.init`. See `API_CONTRACT.md` for the full plan, including why safety routing stays local-first even after a remote provider exists.

## 9. Quick context drives deterministic rules; pasted conversations get an honest, conservative fallback

**Decision:** `ContextSignals` derives reliable structured signals from the closed-choice quick-context answers (who texted last, how long ago, whether they responded) and feeds those into layer 2's rules directly. A pasted conversation, being free text, is **not** deeply parsed — the local provider extracts only one narrow, honest signal from it (`mentionsRepeatedContact`, a short list of self-reported phrases like "already texted") and otherwise treats every structured context signal as unknown. When no layer-2 rule matches, `FallbackJudgment` gives a pasted conversation a moderate, explicitly-labeled-as-limited response (REWRITE IT, with a reason that says the engine can only read the surface of it) rather than pretending to have understood the conversation's history and tone.

**Why:** This is the same principle as decision 1, applied at a finer grain: don't fake understanding you don't have. Genuinely understanding a multi-message conversation — who said what, how long ago, what the emotional arc was — is semantic judgment, which is explicitly reserved for a future AI-backed provider (`API_CONTRACT.md`). Pretending a keyword scan can do that job would reintroduce exactly the kind of overconfident, wrong-too-often behavior this repair exists to fix, just relocated to a new input field. The user-visible tradeoff (quick context gets sharper, more specific reasoning today; pasted conversation gets a more conservative one) is documented in `PRODUCT_SPEC.md` and is worth it for honesty over false confidence.

## 10. The fallback layer no longer defaults to SEND IT

**Decision:** `FallbackJudgment` — the layer reached when no obvious rule applies — checks, in order: is this from a pasted conversation (→ REWRITE IT, conservatively); does the message have a positive/warm signal (→ SEND IT, because that's actually supported by evidence); is there no pending unanswered question in the (quick) context (→ SEND IT, again because context supports it); otherwise → REWRITE IT.

**Why:** This is the direct fix for the reported defect. The old fallback returned SEND IT whenever it ran out of keyword matches, regardless of what the user had actually told it. The new fallback only returns SEND IT when something in the request actually supports it, and defaults to the safer, still-useful REWRITE IT otherwise. `LocalJudgmentProviderFixtureTests.testVerdictsAreMeaningfullyDiverseAcrossFixtures` regression-tests this directly: SEND IT must stay under 60% of outcomes across the fixture suite, and at least 3 distinct verdicts must appear.

## 11. Goal is asked once, not twice

**Decision:** The original build asked "what are you trying to do" only when the user tapped HELP ME REWRITE IT, via a separate `RewriteIntentView` screen. That screen is removed. The goal is now collected once, up front (Step 2), used to judge the message, and reused directly for rewrite suggestions if the user asks for them.

**Why:** Once goal collection moved earlier in the flow to support context-aware judgment, asking it again after the verdict would be pure repetition with no product value — the answer can't have changed in the few seconds since Step 2. Removing the redundant screen also shrinks the app, consistent with the Factory doc's "keep it small" principle.

## 12. Ordered, prioritized rule list instead of a weighted score

**Decision:** `DeterministicJudgmentRules.evaluate` is an ordered list of `if` conditions, each returning immediately on match, rather than a numeric weighted-scoring model.

**Why:** Priority ordering makes the reasoning legible and testable in plain English (see the doc comments in that file) and makes it possible to state, and test, hard invariants like "safety always wins" and "explicit repeated-contact disclosure always wins" without those guarantees being one bad weight tweak away from silently regressing. A scoring model optimizes for aggregate accuracy; this product needs specific guarantees (never encourage harassment, never let anger slip through as a validated boundary) that are much easier to keep true with explicit, ordered rules.

---

## Revision note (semantic judgment architecture)

A second physical-device QA pass found a second release-blocking defect: `hello gangster what the fuck is your problem` still returned SEND IT, because it matched no phrase in `MessageSignals.angerTerms`. The instruction from that report was explicit: don't fix this by adding more hostile phrases — a keyword list can never be complete, and treating "no keyword matched" as "the message is fine" was the actual bug, restated at a lower confidence threshold than the first defect. Decisions 13–17 describe the redesign that made judgment genuinely semantic while keeping safety and a few structural checks deterministic and local. Decisions 1–12 above still hold except where explicitly superseded (called out inline).

## 13. Primary judgment becomes semantic (AI-backed), not keyword-based

**Decision:** `RemoteAIJudgmentProvider`, calling a real AI model through theAIgincy's own server-side proxy, is now the app's default/primary `JudgmentProvider`. `LocalJudgmentProvider` (decision 1's fully on-device engine) is demoted to two roles: the safety/mechanical pre-filter inside `RemoteAIJudgmentProvider`, and the offline/error fallback. *(The model behind this was originally a hosted third-party provider; decision 18 replaced that with a self-hosted local model. The architectural point of this decision — semantic judgment behind the `JudgmentProvider` seam, not keyword matching — is unaffected by which model sits behind it.)*

**Why:** Hostility, sarcasm, passive aggression, manipulation, guilt-tripping, and veiled threats are not enumerable as a keyword list — that was the entire lesson of the second QA defect. Genuinely reading a sentence's meaning requires a language model, not string matching. This directly supersedes decision 1's "local deterministic engine only" choice: decision 1 was right that a from-scratch repo couldn't responsibly stand up a backend on day one with no product validation yet; by this point the product's core judgment logic had been proven insufficient twice, which is exactly the signal decision 1 said would justify the investment. The zero-network, zero-backend properties from decision 1 are preserved for safety-critical and mechanical cases (see decision 14) — they're just no longer asked to do the AI's job.

## 14. Local rules and the local fallback can never return SEND IT

**Decision:** `DeterministicJudgmentRules` has no rule that produces `.send` (four such rules existed briefly after the first redesign — calm-boundary, calm-apology, calm-closure, and positive-reciprocity — all four are removed). `FallbackJudgment`, used when the AI is unavailable, always returns `.rewrite`, never `.send`, regardless of how clean the message looks.

**Why:** This is the direct, generalized fix for both reported defects, stated as a standing invariant rather than a one-off patch. A keyword-based or purely mechanical system can detect the *presence* of specific red flags; it cannot verify the *absence* of every possible problem a real reading would catch (sarcasm, a fake-calm veiled threat, manipulative affection dressed as warmth). Treating "no rule fired" as "safe to send" was the root cause both times. The only path to a confident SEND IT is now genuine semantic judgment, or an explicit, narrow, self-reported positive fact combined with mechanical safety already having cleared the message (which no current rule does alone — see decision 13). This is regression-tested directly (`DeterministicJudgmentRulesTests.testNeverReturnsSendAcrossASweepOfInputs`, `LocalJudgmentProviderFixtureTests.testNeverReturnsSend`, `AdversarialSemanticFixtureTests.testLocalProviderNeverSendsHostileOrManipulativeMessages`).

## 15. Graceful degradation instead of faking confidence when the AI is unavailable

**Decision:** When the network is unreachable, the request times out, or the server's response fails strict validation, the app does not retry silently or substitute a guess dressed up as a real judgment. It falls back to `FallbackJudgment`'s conservative local result, flags it `isLocalFallback = true`, and `VerdictView` shows this honestly (a banner explaining the limitation, plus a "Try again for full analysis" button).

**Why:** The instruction behind this repair was explicit: "do not fake confidence." A confident-looking verdict the user can't distinguish from a real semantic judgment, produced by a keyword-matching fallback, is exactly the failure mode being fixed — just relocated to the "offline" case instead of the "always" case. Labeling the degraded path honestly costs almost nothing and preserves the trust the rest of this fix is built on.

## 16. TypeScript server, structured output via schema validation

**Decision:** The application API (`server/`) is a TypeScript project. Structured-output validation is enforced via a hand-written Zod schema on both the request into and the response out of the model call, rather than trusting any single layer to guarantee shape.

**Why:** TypeScript + Zod gives strict, hand-auditable request/response schemas that can be kept in lockstep with the Swift client's `Codable` types (see `API_CONTRACT.md`) without a code-generation pipeline this project's size doesn't need. Structured-output validation, combined with the client's own independent validation (decision 15's sibling requirement, "validate the response before rendering"), means a malformed model response can never reach the UI unvalidated on either side of the network boundary. **Superseded in part by decision 18**: the original version of this decision also specified Vercel-serverless hosting and a specific hosted model (`claude-opus-5` via the Anthropic SDK) — both are gone; see decisions 18–19 for what replaced them. The TypeScript-with-Zod-schemas choice itself is unchanged.

## 17. No per-caller rate limiting or request authentication on the proxy yet

**Decision:** The original hosted-AI-backed proxy validated request size and shape but had no rate limiting or caller authentication beyond that.

**Why:** Real distributed rate limiting needs an external store (Redis/Upstash/Vercel KV); an in-memory counter in a serverless function resets on every cold start and doesn't work at all across concurrent instances, so it would provide false confidence rather than real protection — worse than clearly documenting the gap. This was a proportionate, explicitly-accepted risk for a Day 1/2 experiment with no production traffic yet. **Superseded by decision 19** once the backend moved off serverless to a persistent process, where an in-memory limiter is no longer false confidence.

---

## Revision note (self-hosted local-inference architecture)

A third instruction, independent of any new QA-found judgment defect, required removing the dependency on a third-party hosted AI provider (Anthropic, OpenAI, or any other paid hosted LLM) for production judgment, and replacing it with a self-hosted local language model. Decisions 18–21 describe that migration. Decisions 1–17 above still hold except where explicitly superseded (called out inline) — the `JudgmentProvider` abstraction (decision 8), the three-layer architecture (decision 7, as generalized by decision 13), and the never-SEND-IT invariant (decision 14) are all unchanged by this migration; only the identity and hosting of the model behind `RemoteAIJudgmentProvider` changed.

## 18. Self-hosted local language model instead of a hosted third-party AI provider

**Decision:** `server/` no longer calls any hosted AI provider's API. It calls a self-hosted local inference server (llama.cpp server, or Ollama's OpenAI-compatible endpoint) over a private connection, via a new provider-neutral `requestLocalJudgment` client (`server/src/lib/localInferenceClient.ts`). The model name and base URL (`LOCAL_LLM_MODEL`, `LOCAL_LLM_BASE_URL`) are read from configuration and never hard-coded into application logic. There is no `ANTHROPIC_API_KEY`, no Anthropic SDK dependency, and no other hosted-provider credential anywhere in this project any more.

**Why:** This was an explicit, non-negotiable instruction: no paid hosted LLM provider for production judgment. The architecture this replaces (decisions 13/16) already isolated "the thing that calls a model" behind the `JudgmentProvider`/server-proxy seam specifically so the model backend could be swapped without touching the client or the UI — this migration is that seam being used exactly as designed, not a rearchitecture of the app. The product-behavior requirements (never SEND IT locally, safety routing stays deterministic and local, absence of a problem is not evidence for send) are all backend-agnostic and are unchanged by this decision.

## 19. Persistent Node/Express service instead of a serverless function

**Decision:** `server/` is now a small, long-running Node/Express process (`server/src/server.ts`), not a Vercel serverless function. It is deployed via Docker Compose (colocated with the inference server on one private network) or bare-metal/systemd — see `server/README.md`.

**Why:** A serverless function's lifecycle (frequent cold starts, no guaranteed persistent process) is a poor fit for two things this migration needed: (1) a real, working in-memory rate limiter (decision 17 explicitly rejected this in the serverless case because it reset on every cold start and didn't work across concurrent instances — a persistent single process doesn't have that problem for the "single instance" case, so it's no longer false confidence, just a documented single-instance limitation); (2) proximity to a self-hosted inference server, which is naturally deployed as a persistent process itself (llama.cpp server, `ollama serve`) — colocating the application API as a persistent process alongside it, on one private network, is simpler than bridging a serverless function to private self-hosted infrastructure on every cold start.

## 20. NEED MORE CONTEXT as a first-class fifth verdict

**Decision:** Added `Verdict.needContext` (wire value `need_context`) and `RecommendedAction.addContext` (wire value `add_context`). The model is instructed that `send` requires affirmative evidence of three things (appropriate tone, goal advancement, context doesn't contradict sending) — not just the absence of a detected problem — and that when the message/goal are clear but supplied context is too thin to judge those three confidently, `need_context` is the correct, preferred answer rather than a guess in either direction. The UI (`VerdictView`) shows this as **NEED MORE CONTEXT.** with an **ADD MORE CONTEXT** control that returns to Step 3 with everything already entered intact (`JudgeViewModel.returnToAddContext()`), never as a dead end.

**Why:** This was an explicit instruction, and it closes a gap the four-verdict model couldn't express honestly: previously, a model that genuinely lacked enough information to judge had no way to say so — it had to pick one of four verdicts that all implicitly claim some level of judgment confidence it didn't have. This is the same "don't fake confidence" principle behind decision 15 (graceful degradation when the AI is unreachable), applied to the case where the AI *is* reachable but the *input* is insufficient rather than the *service* being down.

## 21. A model benchmark harness, not a fixed model choice

**Decision:** `server/scripts/benchmark.ts` runs the same 60 adversarial fixtures used by the iOS test suite (mirrored in wire format at `server/benchmark/fixtures.json`) against a configurable model/base-URL, and reports acceptable-verdict rate, SEND IT false positives, a heuristic critical-safety-failure count, malformed-response rate, and latency, against a documented pass/fail threshold (`server/README.md` → "Model benchmark harness"). No specific model (`qwen3:8b`, `qwen3:4b`, `llama3.2:3b`, or any other) is hard-coded as "the" model — the harness exists specifically so the choice is evidence-based.

**Why:** Self-hosted local models vary enormously in judgment quality and instruction-following reliability compared to a large hosted frontier model, and vary among themselves by size — this was an explicit instruction not to assume one model wins, and not to select based on speed alone. Building the harness against the exact same fixtures the iOS app is regression-tested against means a "passing" model is validated against the same product-intent bar the client-side tests enforce, not a separate or looser one. The harness calls the same prompt/schema/client code the live `/api/judge` route uses, so a benchmark result is a real signal about production behavior, not a simulation that could drift from what actually ships.
