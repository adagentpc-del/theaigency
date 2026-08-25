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
