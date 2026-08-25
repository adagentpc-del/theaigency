# App Store Metadata Draft — Should I Text Him?

Draft only. Every field must be re-verified against the actual shipped build and current App Store Connect requirements before submission (`RELEASE_CHECKLIST.md`).

## App name

**Should I Text Him?**

## Subtitle (30 chars max)

**Judge it before you send it** *(29 chars)*

## Promotional text (170 chars max, optional/updatable without review)

Paste the text. Get a verdict. Send it, rewrite it, sleep on it, or don't. Zero accounts, zero data leaves your phone.

## Description

```
Before you send the text you may regret, run it through the app.

Paste what you're about to send. Get one clear verdict:

SEND IT.
REWRITE IT.
SLEEP ON IT.
DON'T SEND IT.

Then a short, honest reason — no essay, no lecture.

If it needs work, tell us what you're actually trying to do
(flirt, make plans, get clarity, apologize, set a boundary, get
closure, or just say less) and get up to three rewrite options
you can copy and use immediately.

WHY IT'S DIFFERENT
— No account. No login. No history saved.
— Nothing you paste ever leaves your phone.
— Funny and sharp, never clinical, never a lecture.
— Built for the moment right before you hit send.

Should I Text Him? isn't therapy, legal advice, or relationship
counseling — it's a fast, honest gut-check for the text that's
been sitting in your drafts too long.
```

## Keywords (100 chars max, comma-separated, no spaces after commas)

```
text,texting,dating,relationship,advice,should i text him,rewrite,breakup,situationship,dating app
```

## Category recommendation

**Primary:** Lifestyle
**Secondary (optional):** Social Networking

Rationale: the app is a personal decision-support/entertainment utility around social communication, not a health/medical or productivity tool — Lifestyle fits Apple's category definitions best and matches comparable apps' placement.

## Age rating considerations

Expect a **12+** or **17+** rating depending on Apple's current questionnaire wording for "Mature/Suggestive Themes" and "Profanity or Crude Humor" — the app's tone is sharp/sassy and the safety-routing feature (`AI_SAFETY.md`) explicitly means the app can be given text referencing violence, self-harm, or sexual content, even though it responds calmly rather than graphically. Answer the age-rating questionnaire honestly based on:
- Infrequent/Mild Mature/Suggestive Themes: **Yes** (dating/relationship context)
- Profanity or Crude Humor: **Yes, Infrequent/Mild** (the tone is sassy; review actual shipped copy against Apple's current definitions before answering)
- References to violence/self-harm: the app never depicts or generates these — it only detects and calmly declines to engage with them if the *user* writes them. Whether this triggers a rating flag is an Apple Review judgment call — flag for founder review, not a self-certifiable "No."

**This section is a starting point, not a final answer — the age rating questionnaire must be completed directly in App Store Connect against Apple's current wording at submission time.**

## Privacy URL

`https://theAIgincy.com/apps/should-i-text-him/privacy`

## Support URL

`https://theAIgincy.com/apps/should-i-text-him/support`

Both must be live, real pages before submission — see `FOUNDER_ACTION_REQUIRED.md`. Do not submit with placeholder/404 URLs.

## App Review notes (draft)

```
Should I Text Him? judges a pasted message and returns a verdict
(Send it / Rewrite it / Sleep on it / Don't send it) plus an
optional rewrite. All judgment logic runs on-device — the app
makes no network requests, requires no account, and stores no
user content beyond the current session (see PRIVACY_DATA_MAP.md
in the source repo for full detail).

The app includes a safety-routing feature: if the pasted message
itself contains language indicating violence, self-harm, coercion,
stalking, sexual exploitation, or abuse, the app returns a calm,
non-comedic "Don't send it" response instead of its usual witty
tone, and hides the rewrite/share actions for that result. This is
implemented as a local, deterministic pattern match
(see AI_SAFETY.md) — there is no live moderation service.

To test the safety-routing path, paste a message containing an
explicit threat (e.g. "I will hurt you if you don't answer") and
confirm the app returns a calm decline rather than a joke.

The app is not therapy, counseling, or a crisis service, and does
not claim to be — this is stated in the app's own copy.
```

## Screenshot shot list

1. Input screen with a relatable example message pasted in, CTA visible.
2. Verdict screen — **SEND IT.** (green), showing the reason text.
3. Verdict screen — **REWRITE IT.** (orange), showing HELP ME REWRITE IT button.
4. Rewrite-intent screen showing the 7 intent options.
5. Rewrite-result screen with 2–3 rewrite options and Copy buttons visible.
6. (Optional) Verdict screen — **DON'T SEND IT.** (red), to show range without using a real high-risk example — use an angry/insulting sample message, not a safety-routed one, for a store screenshot.

All screenshots must be captured from the actual running app on the target device sizes Apple currently requires — no mockups/composited text. See `FOUNDER_ACTION_REQUIRED.md`.

## Promotional / social hooks

- "POV: you're about to send THAT text at 1am" + screen recording of pasting a spicy message and getting DON'T SEND IT.
- "I let an app judge my texts for a week" video hook.
- Before/after: original message vs. one of the rewrite options.
- Duet/stitch bait: "guess the verdict before it loads."

## What this app does not claim

Per `PRODUCT_SPEC.md` and `AI_SAFETY.md`: no claim of being AI-powered in the sense of a hosted model (it isn't, in this release — see `DECISIONS.md`), no therapy/counseling/legal/medical claim, no claim of certainty about another person's intentions or character. Marketing copy must stay inside these lines.
