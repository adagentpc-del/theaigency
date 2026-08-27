# Start Me — App Store Metadata

Status: draft copy ready; URLs and screenshots are **not live** — see
`FOUNDER_ACTION_REQUIRED.md`. Do not submit until every placeholder below
is resolved.

## Name

**Start Me**

## Subtitle (30 chars max — pick one)

- "Stop Procrastinating. Start." (29 chars)
- "One tiny step. 60 seconds." (27 chars)

## Category

Primary: Productivity (`public.app-category.productivity`, set in
`Info.plist`). Secondary: none needed.

## Promotional text (170 chars, editable without review)

> Type the thing you're stuck on. Get one tiny physical first step and a
> 60-second timer. No plan, no guilt — just start.

## Description

```
You don't need another to-do list.

You already know what you need to do. You're just stuck on starting it.

Start Me gives you the smallest possible first step and a 60-second timer
to help you begin — nothing more.

  "clean my kitchen" -> Throw away one piece of trash.
  "go to the gym" -> Put your shoes on.
  "answer emails" -> Open your inbox.

No giant plan. No guilt. No account. Just start.

WHAT IT DOES
- Type what you're stuck on, in your own words.
- Get one tiny, physical first action — always smaller than the task.
- Not small enough? Tap "Make it even smaller."
- Not the right start? Tap "Give me a different start."
- Run a 60-second timer. That's the whole commitment.
- Keep going for 5 more minutes, or stop — either way, you started.

WHAT IT ISN'T
Start Me is not a planner, a habit tracker, a Pomodoro system, or an AI
coach. It doesn't manage your to-do list or your calendar. It does one
thing: it gets you moving on the thing you're avoiding.

PRIVACY
Everything runs on your device. Start Me has no account, no ads, no
tracking, and no backend — what you type never leaves your phone. See our
privacy policy for details.

Free to use.
```

## Keywords (100 chars, comma-separated, no spaces after commas)

`procrastination,focus,task,paralysis,productivity,motivation,overwhelm,timer,start,adhd`

(No keyword-stuffing beyond this single field; no repeated words across
name/subtitle/keywords beyond what's naturally needed.)

## What's New (v1.0.0)

> First release: type a task, get one tiny first step, run a 60-second
> timer. No account required.

## Support URL

`https://theAIgincy.com/apps/start-me/support` — **placeholder, not live.**
See `FOUNDER_ACTION_REQUIRED.md`.

## Privacy Policy URL

`https://theAIgincy.com/apps/start-me/privacy` — **placeholder, not live.**
See `FOUNDER_ACTION_REQUIRED.md`.

## Age rating

Recommended answers (re-verify against the current App Store Connect
questionnaire at submission time — do not assume this list is exhaustive
or unchanged, per `MICRO_APP_FACTORY.md` §10):

- No objectionable content of any kind (violence, sexual content,
  profanity, gambling, alcohol/drugs, horror) — all **None**.
- No unrestricted web access, no user-generated content shared with other
  users, no third-party ads.
- Expected result: **4+**.

## App Privacy questionnaire

See `docs/PRIVACY_DATA_MAP.md` §"Tracking status" for the recommended
answers (no tracking, no data collected).

## In-app purchases

None in V1 — see `docs/MONETIZATION.md`. "Restore Purchases" is not
applicable.

## Screenshots

**Not yet produced.** Requires a simulator or device running the built
app. Recommended set (iPhone 6.7" + 6.5" + iPad if supporting iPad):
1. Home screen with a task typed in.
2. Starter screen showing a tiny action ("Put your shoes on.").
3. Timer screen mid-countdown.
4. Completion screen ("You started.").
5. Stats line on Home ("You started 4 things today.").

See `FOUNDER_ACTION_REQUIRED.md`.

## App icon

**Not yet produced** — see `FOUNDER_ACTION_REQUIRED.md` and
`docs/POST_LAUNCH.md`. The `AppIcon.appiconset` asset slot exists
(`StartMe/Assets.xcassets/AppIcon.appiconset/Contents.json`, single
1024×1024 universal slot per current Apple requirements) but contains no
image. Design direction: movement/ignition — not a checkmark, stopwatch,
or generic to-do-list icon; not purple/neon "AI product" styling (the
app's own accent color is a warm ember-orange, chosen specifically to
avoid that look — see `DesignSystem/Theme.swift`).

## Short-form marketing hooks (for TikTok/Reels — spec §40)

Each follows: hook (1–2s) -> show the stuck problem -> show the app ->
show the satisfying tiny result -> simple CTA. Twenty variations across
categories:

1. "I've needed to clean my apartment for three hours and instead I've
   been scrolling." -> types `clean apartment` -> "Stand up. Throw away
   one thing. 60 seconds." -> cut to still cleaning. Caption: "This
   stupid app tricked me into cleaning my apartment."
2. Laundry: "The laundry has been in the basket for a week." -> `do my
   laundry` -> "Pick up one piece of clothing." -> cut to folding a full
   load. Caption: "One piece of clothing turned into the whole basket."
3. Gym: "I have a $40/month gym membership I have used twice." -> `go to
   the gym` -> "Put your shoes on." -> cut to gym mirror selfie. Caption:
   "It only asked for my shoes."
4. Dishes: "The sink has achieved sentience." -> `do the dishes` -> "Put
   one dish in the sink." — wait, they're already there -> next reduction
   "Run the water and rinse one dish." -> cut to empty sink. Caption:
   "It only asked for one dish."
5. Studying: "Exam in 2 days, zero pages read." -> `start studying` ->
   "Open the material." -> cut to 3 highlighted pages later. Caption: "I
   opened a textbook and couldn't stop."
6. Emails: "47 unread and climbing." -> `answer emails` -> "Open your
   inbox." -> cut to inbox zero. Caption: "It didn't even ask me to
   reply. I just kept going."
7. Packing: "Flight's in 5 hours, suitcase is empty." -> `pack for my
   trip` -> "Put your bag where you can reach it." -> cut to zipped
   suitcase. Caption: "That's it. That's the whole trick."
8. Résumé: "Haven't touched my résumé in 2 years." -> `work on my resume`
   -> "Open the document." -> cut to updated résumé. Caption: "Opening it
   was the hard part."
9. Taxes: "It's April and I have not started." -> `file my taxes` ->
   "Open the website or folder you use for your taxes." -> cut to
   submitted confirmation. Caption: "I just had to open the folder."
10. Shower: "Haven't showered today and it's 4pm." -> `take a shower` ->
    "Walk to the bathroom." -> cut to clean and dressed. Caption: "It
    only asked me to walk there."
11. Phone calls: "I've been avoiding this call for a week." -> `call the
    dentist` -> "Find the phone number." -> cut to call ending. Caption:
    "Finding the number was 90% of my anxiety."
12. Work tasks: "The report is due tomorrow and I have a blank page." ->
    `finish the report` -> "Open the file or project." -> cut to
    finished doc. Caption: "The blank page was the scary part, not the
    writing."
13. Cleaning (bathroom): "The bathroom has been 'on my list' for a
    month." -> `clean the bathroom` -> "Throw away one piece of trash."
    -> cut to sparkling sink. Caption: "One piece of trash led to a full
    clean."
14. Grocery shopping: "Fridge is empty, I keep ordering delivery." ->
    `grocery shopping` -> "Make a list of the one or two things you
    actually need." -> cut to full cart. Caption: "It only asked for two
    things."
15. Organizing: "My closet is a crime scene." -> `organize my closet` ->
    "Pick up one item that needs a home." -> cut to organized closet.
    Caption: "One item. That's all it asked."
16. Cooking: "Been ordering takeout for 2 weeks." -> `cook dinner` ->
    "Take out one ingredient." -> cut to plated meal. Caption: "It didn't
    ask me to cook. It asked me to open the fridge."
17. Admin: "This form has been open in a tab for 3 days." -> `fill out
    the form` -> "Open the form or document you need." -> cut to
    submitted form. Caption: "Already open. I just had to look at it."
18. Errands: "Post office closes in an hour and I haven't left." ->
    `run errands` -> "Find your keys and wallet." -> cut to walking out
    the door. Caption: "60 seconds later I was in the car."
19. Vague/slang: "I need to get my life together but bed is comfortable."
    -> `get my shit together` -> "Open the thing you need." -> cut to
    person up and moving. Caption: "It didn't ask for a life plan. It
    asked for one thing."
20. General/relatable close-out: "Whatever you're avoiding right now —"
    -> app opens, task typed, tiny action appears -> "60 seconds. Go."
    Caption: "Tell it the thing. It'll give you the first move."

## Review notes (draft — fill in specifics before submission)

> Start Me is a fully local iOS utility with no account, no backend, and
> no AI. Typing a task and tapping START ME produces a tiny first physical
> step and a 60-second on-device timer. No login is required or possible.
> No special test credentials are needed. If you type something involving
> self-harm or harm to others, the app declines with a generic message
> instead of generating a step — this is intentional (see in-app behavior
> for any such input).
