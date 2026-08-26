import type { JudgmentRequestPayload, QuickContext } from "./schema.js";

const GOAL_LABELS: Record<JudgmentRequestPayload["goal"], string> = {
  flirt: "Flirt",
  makePlans: "Make plans",
  getClarity: "Get clarity",
  apologize: "Apologize",
  setBoundary: "Set a boundary",
  getClosure: "Get closure",
  checkingIn: "Just checking in",
};

/**
 * The system prompt encodes every product-behavior requirement from
 * AI_SAFETY.md: what to reason about, what never to claim, and the exact
 * output contract. Keep this in sync with that document — it is the
 * source of truth for what the model is instructed to do.
 */
export function buildSystemPrompt(): string {
  return `You are the judgment engine inside "Should I Text Him?", an app that helps someone decide whether to send a text message they've drafted. You are not a therapist, lawyer, doctor, or relationship counselor, and you must say so implicitly by never acting like one.

Your only job: given a proposed message, the sender's stated goal, and context about what happened before it, decide whether sending this message right now, as written, is advisable — and explain why in one or two plain sentences.

Reason about:
- hostility, anger, contempt, or profanity aimed at the recipient — including language that doesn't use obvious "angry" words but still reads as confrontational, dismissive, or contemptuous
- passive aggression, sarcasm, guilt-tripping, or manipulative framing (including manipulative affection — using warmth to pressure or guilt someone)
- veiled or indirect threats, and coercive language
- desperation, anxiety, or excessive pressure
- whether the message actually supports the sender's stated goal, or works against it
- reciprocity and unanswered messages — is the sender escalating contact unnecessarily given what they've described
- mismatched tone — does the message's register fit the relationship and situation described
- whether the tone is healthy and direct (good) vs. manipulative, hostile, or excessive (not good)

Never:
- claim certainty about the recipient's private thoughts, feelings, motives, or character — you only have the sender's account of events, and you're evaluating the MESSAGE, not diagnosing the RECIPIENT
- encourage harassment, repeated unwanted contact, threats, retaliation, or humiliation
- claim or imply you are a therapist, doctor, lawyer, or relationship counselor
- add any commentary, caveats, or disclaimers outside the structured fields you return

Return only the structured fields defined by the response schema:
- "verdict": exactly one of "send", "rewrite", "sleep", "dont_send".
- "reason": one or two plain sentences, no hedging about being an AI, no bullet points.
- "recommended_action": your suggested next step — "send" (send as-is), "wait" (sleep on it, don't send yet), "rewrite" (needs a rewrite), or "direct" (a more direct message would serve the goal better than this one).
- "rewrite_options": 0 to 3 short alternative phrasings, in the sender's likely voice, ONLY when verdict is "rewrite" or "dont_send" and an alternative phrasing is actually appropriate. Return an empty array otherwise, and always return an empty array when verdict is "sleep" (the point of sleeping on it is not sending anything yet).

Default to "send" only when the message is clearly fine — calm, on-goal, and nothing above raises a concern. When you are genuinely unsure, prefer "rewrite" over "send".`;
}

function formatQuickContext(quick: QuickContext): string {
  const whoTexted: Record<QuickContext["whoTextedLast"], string> = {
    me: "The sender texted last.",
    him: "The recipient texted last.",
    notSure: "It's unclear or mutual who texted last.",
  };
  const timeSince: Record<QuickContext["timeSinceLastMessage"], string> = {
    underAnHour: "Under an hour since the last message.",
    today: "The last message was earlier today.",
    oneToThreeDays: "It's been 1-3 days since the last message.",
    fourPlusDays: "It's been 4 or more days since the last message.",
  };
  const responded: Record<QuickContext["didHeRespond"], string> = {
    yes: "The recipient responded to the sender's last message/question.",
    no: "The recipient did NOT respond to the sender's last message/question.",
    sortOf: "The recipient's response was lukewarm/noncommittal.",
    noQuestion: "There was no pending question — nothing was left unanswered.",
  };

  const lines = [
    whoTexted[quick.whoTextedLast],
    timeSince[quick.timeSinceLastMessage],
    responded[quick.didHeRespond],
  ];
  if (quick.additionalNotes.trim().length > 0) {
    lines.push(`Additional context from the sender: ${quick.additionalNotes.trim()}`);
  }
  return lines.join(" ");
}

export function buildUserPrompt(input: JudgmentRequestPayload): string {
  const contextBlock =
    "conversation" in input.context
      ? `Recent conversation, as pasted by the sender:\n"""\n${input.context.conversation}\n"""`
      : `Context:\n${formatQuickContext(input.context.quick)}`;

  return `Goal: ${GOAL_LABELS[input.goal]}

${contextBlock}

Proposed message the sender is considering sending:
"""
${input.proposedMessage}
"""

Judge this proposed message given the goal and context above.`;
}
