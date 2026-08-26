# Product Spec — Should I Text Him?

## Promise

Before you send the text you may regret, run it through the app.

## Target user

Someone about to send a text in a charged moment (romantic interest, ex, situationship, friend-group drama) who wants a fast, honest, non-judgmental gut-check before hitting send.

## Success event

User reaches a verdict in under ~10 seconds of active input (excluding the few seconds spent typing/pasting into each of the three steps).

## Why a 3-step flow instead of "judge the message alone"

The first build judged the pasted message in isolation and, in real QA, defaulted to **SEND IT** for far too many materially different situations — it had no way to know whether the user was flirting or already being ignored. A message can only be judged correctly with:

1. what the user is trying to accomplish, and
2. what happened right before this message.

So judgment is now a 4-step flow, and **judgment never runs until all three inputs exist.**

A second QA pass then found that goal and context alone weren't enough either: a purely keyword-based engine still couldn't recognize hostility, sarcasm, or manipulation outside a fixed phrase list (`"hello gangster what the fuck is your problem"` returned SEND IT). Primary judgment is now genuinely semantic — a real AI model, called through theAIgincy's own server-side proxy, reads the actual message/goal/context. Safety routing and a few structural checks (repeated contact, double-texting, message length, breakup topic) still run entirely on-device first and never depend on the network. See `DECISIONS.md` for the full engineering rationale and `AI_SAFETY.md`/`API_CONTRACT.md` for the architecture.

## Screens

### Step 1 of 3 — Proposed Message (`MessageStepView`)

- App name: **Should I Text Him?**
- Supporting line: *Before you send it, run it by us.*
- Prompt: *What are you thinking about sending?*
- Large multiline text field, placeholder: *Paste what you're about to send...*
- Primary CTA: **NEXT**

States: empty/whitespace-only disables NEXT; a Clear button appears once text is entered; keyboard has a Done button. **No judgment happens on this screen.**

### Step 2 of 3 — Goal (`GoalStepView`)

Prompt: *What are you actually trying to accomplish?*

Single-choice list: Flirt · Make plans · Get clarity · Apologize · Set a boundary · Get closure · Just checking in.

A selection is required to advance. This answer is stored for the whole session — it is never asked again, including during the rewrite flow later.

### Step 3 of 3 — Context (`ContextStepView`)

Prompt: *Okay. What happened before this?*

Two mutually exclusive ways to answer, picked via a segmented control:

**Option A — Paste the conversation.** A large multiline field ("Paste the recent conversation here...") with a caption explaining only the relevant recent portion is needed, and a second caption clarifying it's only sent to get a verdict — never stored, never shown to anyone else. See `DECISIONS.md`/`AI_SAFETY.md` for what the local engine does and does not do with this free text before it's sent for semantic judgment.

**Option B — Quick context.** Three required single-choice questions:
- *Who texted last?* — Me / Him / Not sure / mutual
- *How long since the last message?* — Under an hour / Today / 1–3 days / 4+ days
- *Did he respond to your last message/question?* — Yes / No / Sort of / There wasn't a question

Plus one optional short free-text field: *Anything else I should know?*

The **JUDGE MY TEXT** CTA is disabled until either Option A has non-blank text or all three Option B questions are answered. Tapping it shows the same loading state pattern as before ("Reading the room…") and only then triggers Step 4.

### Step 4 — Judgment (`VerdictView`)

Runs only after message + goal + context are all present (`JudgeViewModel.submitContext()`). One of the four verdicts, unchanged:

| Verdict | Symbol | Color |
|---|---|---|
| SEND IT. | `paperplane.fill` | green |
| REWRITE IT. | `pencil.line` | orange |
| SLEEP ON IT. | `moon.zzz.fill` | blue |
| DON'T SEND IT. | `hand.raised.fill` | red |

A small "Goal: <goal>" caption is shown above the verdict for transparency about what the app judged against. The reason explicitly connects the verdict to goal and/or context (e.g. *"You already asked a direct question and haven't gotten an answer. Another casual check-in probably won't get you the clarity you're looking for."* — see `PRODUCT_SPEC.md`'s worked example reproduced exactly in `ACCEPTANCE_CRITERIA.md` and the fixture suite).

Controls: **HELP ME REWRITE IT** (hidden for safety-routed results), **START OVER**, and a privacy-safe text share (hidden for safety-routed results).

### Rewrite Result (`RewriteResultView`)

Since the goal was already collected in Step 2, tapping **HELP ME REWRITE IT** goes straight to up to 3 rewrite options for that goal — there is no second "what are you trying to do" prompt. Each option has a **Copy** button; **Start Over** returns to Step 1.

## Tone

Unchanged: funny, sharp, confident, concise, socially aware, non-clinical. The app never diagnoses the other person, claims certainty about their motives, encourages harassment/stalking/coercion/retaliation/humiliation/abuse, or presents itself as therapy/legal/medical/professional counseling.

## Data behavior

No account, no history, no cloud sync, no persistence anywhere in the pipeline. This is the first release where user content leaves the device in normal operation — the proposed message, goal, and context are sent to theAIgincy's server to obtain a semantic judgment (see "Why a 3-step flow" above and `API_CONTRACT.md`). Safety-flagged and repeated-contact-flagged requests never leave the device at all. Nothing is logged or stored anywhere in the pipeline (device, proxy, or model provider) — see `PRIVACY_DATA_MAP.md` for the full, updated data map.

## Monetization

Unchanged: free at launch, no subscriptions, no IAP in this release.

## Edge cases handled

- Blank/whitespace message at Step 1 (NEXT disabled).
- Quick context left partially answered (JUDGE MY TEXT disabled until all three are set).
- Pasted conversation left blank while Option A is selected (JUDGE MY TEXT disabled).
- Very long proposed message (100+ words) → REWRITE IT regardless of goal.
- High-risk content anywhere the user typed (proposed message, pasted conversation, or the optional notes field) → safety-routed to a calm DON'T SEND IT, with rewrite/share hidden.
- Back navigation from Step 2 → Step 1 and Step 3 → Step 2 without losing what was already entered.
- Relaunch — no state persists between launches.
- Large Dynamic Type / Reduce Motion — unchanged from the first release; see `ACCESSIBILITY_CHECKLIST.md`.
- Identical proposed message with different context produces different verdicts — this is the core regression test in `LocalJudgmentProviderFixtureTests` proving the first reported defect is fixed.
- Hostile/manipulative messages that match no keyword pattern (e.g. the exact profanity regression from the second QA pass) never return SEND IT — see `AI_SAFETY.md` and `AdversarialSemanticFixtureTests`.
- AI judgment service unavailable (offline, timeout, invalid response) → a conservative local result, clearly labeled as limited, with a retry option — never a confident-looking guess.

## Explicitly out of scope for this iteration

See `POST_LAUNCH.md`.
