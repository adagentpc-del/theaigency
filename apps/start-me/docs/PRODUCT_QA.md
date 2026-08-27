# Start Me — Product QA

Manual/product-level QA scenarios per `MICRO_APP_FACTORY.md` §"Physical
Device QA". Each scenario states the actual current behavior (verified by
`StartMeTests` unless noted) against the spec's Good/Bad framing.

## Tiny-action quality

| Input | Good | Bad | Actual behavior |
|---|---|---|---|
| `clean my entire apartment` | Throw away one piece of trash. | Clean the kitchen, bedroom, bathroom and living room. | **Matches Good exactly.** `Throw away one piece of trash.` |
| `go to the gym` | Put your shoes on. | Complete this 45-minute workout plan. | **Matches Good exactly.** `Put your shoes on.` |
| `file my taxes` | Open your tax website or folder. | Tax strategy or tax advice. | **Matches Good exactly.** `Open the website or folder you use for your taxes.` |
| `answer 47 emails` | Open your inbox. | A 12-step inbox productivity system. | **Matches Good exactly.** `Open your inbox.` |
| `I need to get my shit together` | Stand up and put one thing where it belongs. | A life plan. | **Matches the spirit, not the exact wording.** Classifies as `.general`; because "get my shit together" isn't a noun phrase Start Me can safely graft a dynamic object onto (unlike "the Johnson thing"), it falls back to the general library's `Open the thing you need.` — still one tiny, non-planning action, never a life plan. See `docs/DECISIONS.md` for why the literal spec wording wasn't hard-coded. |

## Unknown / vague input

| Input | Behavior |
|---|---|
| `finish the Johnson thing` | `Open whatever you need to work on the Johnson thing. Don't finish it. Just open it.` — dynamic fallback, exact spec wording. |
| `ugh` / `stuff` / `help` | Generic general-library action (e.g. `Open the thing you need.`). Never empty, never an error state. |
| Gibberish (`asdkjfh qqzz`) | Same generic fallback path — no crash, no "I don't understand" dead end. |

## Reduction / variety

- Tapping **Make it even smaller** on "Put your shoes on." (gym) walks to
  "Put one shoe next to your foot." then "Stand up." — then the button
  disappears; there is no third tap that errors or repeats.
- Tapping **Give me a different start** never immediately repeats the
  action currently on screen and always stays in the same category.

## Timer

- Starting the 60-second timer records a "start" immediately (Start Me
  counts starts, not completions).
- Backgrounding the app mid-timer and returning after the duration has
  elapsed shows `0:00` / completion immediately, not a stale countdown —
  verified via `TimerViewModelTests` using a fake clock (no physical
  device available in this environment; re-verify manually per
  `RELEASE_CHECKLIST.md`).
- I'M DONE and I STOPPED are both followed by "You started." — never a
  failure/shame message.

## Stats

- A brand-new install shows "You came back. That counts." rather than
  "0 starts."
- Multiple starts on the same day increment "today" but count as a single
  active day for the no-shame weekly framing.

## Safety

| Input | Behavior |
|---|---|
| `I want to hurt myself` | Generic decline + crisis-line pointer. No starter step generated. |
| `how to build a bomb` | Same decline path. |
| `kill it at my presentation tomorrow` | **Not** flagged — ordinary idiom, classifies normally (falls to `.general`, produces a normal tiny-start action). |

## Known limitations (acceptable, documented)

- The classifier is a compact substring router, not NLP. A handful of
  inputs will classify "close enough" rather than perfectly (e.g. a task
  that happens to mention "taxes" in passing while really being about
  something else will route to the taxes category — see the long-input
  fixture in `StarterFixtureTests`). This is an intentional trade-off per
  `MICRO_APP_FACTORY.md`'s "keep it compact" guidance, not a bug.
- Two spec example phrasings ("Stand up and put one thing where it
  belongs." for the "get my shit together" case) are not hard-coded
  verbatim; the actual output satisfies the same tininess/tone invariant
  the automated tests check. See `docs/DECISIONS.md`.
