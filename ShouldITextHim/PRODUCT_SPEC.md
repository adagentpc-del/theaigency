# Product Spec — Should I Text Him?

## Promise

Before you send the text you may regret, run it through the app.

## Target user

Someone about to send a text in a charged moment (romantic interest, ex, situationship, friend-group drama) who wants a fast, honest, non-judgmental gut-check before hitting send.

## Success event

User reaches a verdict in under ~10 seconds from opening the app.

## Screens

### 1. Main Input (`InputView`)

- App name: **Should I Text Him?**
- Supporting line: *Before you send it, run it by us.*
- Large multiline text field, placeholder: *Paste what you're about to send...*
- Primary CTA: **JUDGE MY TEXT**
- Clear button appears once text is entered.

States:
- **Empty** — CTA disabled.
- **Whitespace-only** — CTA disabled (trimmed check).
- **Valid text** — CTA enabled.
- **Judging** — CTA becomes a progress indicator ("Reading the room…"), text field disabled, keyboard dismissed.

### 2. Verdict (`VerdictView`)

One of four prominent verdicts, each with a distinct color *and* SF Symbol *and* label (never color-only):

| Verdict | Symbol | Color |
|---|---|---|
| SEND IT. | `paperplane.fill` | green |
| REWRITE IT. | `pencil.line` | orange |
| SLEEP ON IT. | `moon.zzz.fill` | blue |
| DON'T SEND IT. | `hand.raised.fill` | red |

Below: one concise reason (one to two sentences, no essay).

Controls:
- **HELP ME REWRITE IT** — starts the rewrite-intent flow. Hidden for safety-routed results (see `AI_SAFETY.md`).
- **START OVER** — always available, returns to a blank input screen.
- **Share result** — `ShareLink` sharing only the verdict headline and app name as plain text. Hidden for safety-routed results. The user's original message is never included in the shared content.

### 3. Rewrite Intent (`RewriteIntentView`)

Prompt: *What are you actually trying to do?*

Options (single choice): Flirt · Make plans · Get clarity · Apologize · Set a boundary · Get closure · Say less.

### 4. Rewrite Result (`RewriteResultView`)

Up to 3 concise rewrite options for the chosen intent, each with a **Copy** button (writes to the system clipboard, shows a "Copied to clipboard" confirmation). **Start Over** returns to a blank input screen.

## Tone

Funny, sharp, confident, concise, socially aware, non-clinical. The app never:

- diagnoses the other person,
- claims certainty about someone else's motives or intentions,
- tells the user someone is definitely cheating, lying, narcissistic, abusive, etc. from insufficient evidence,
- encourages harassment, repeated unwanted contact, stalking, retaliation, threats, coercion, humiliation, or abuse,
- implies it is therapy, legal advice, medical advice, or professional relationship counseling.

When context is insufficient, the reason says so rather than inventing certainty.

## Data behavior

- No account, no login.
- No conversation history, no cloud sync.
- The pasted message lives only in view-model memory for the current session; it is never written to disk, UserDefaults, or logs.
- No network requests happen at all in this release (see `DECISIONS.md`).

Full detail in `PRIVACY_DATA_MAP.md`.

## Monetization

Free at launch. No subscriptions, no IAP in this release. See `DECISIONS.md` and `POST_LAUNCH.md` for the deferred one-time-unlock path.

## Edge cases handled

- Blank / whitespace-only input (CTA stays disabled).
- Very long input (100+ words) → routed to REWRITE IT with a "trim it down" reason.
- Multiline input.
- High-risk content (threats, self-harm, coercion, stalking, sexual exploitation, abuse indicators) → safety-routed to a calm DON'T SEND IT response; rewrite and share are hidden for these results.
- Relaunch — no state persists between launches; the app always opens on a blank input screen.
- Large Dynamic Type — layout uses `ScrollView`/`TextEditor` and system fonts, no fixed-height text truncation.
- Reduce Motion — phase transitions are skipped (not slowed) when Reduce Motion is on.

## Explicitly out of scope for v1

See `POST_LAUNCH.md`.
