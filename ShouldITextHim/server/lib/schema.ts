import { z } from "zod";

/**
 * Mirrors the Swift models exactly (Models/Goal.swift, QuickContext.swift,
 * ContextInput.swift, JudgmentRequest.swift) — same raw values, same
 * Codable shape for the enum-with-associated-value `ContextInput`, so the
 * client can `JSONEncoder().encode(request)` with zero custom encoding
 * logic. Keep these two schemas in lockstep with the Swift models by hand;
 * there is no shared code generation for a project this small.
 */

export const GoalSchema = z.enum([
  "flirt",
  "makePlans",
  "getClarity",
  "apologize",
  "setBoundary",
  "getClosure",
  "checkingIn",
]);
export type Goal = z.infer<typeof GoalSchema>;

export const QuickContextSchema = z.object({
  whoTextedLast: z.enum(["me", "him", "notSure"]),
  timeSinceLastMessage: z.enum([
    "underAnHour",
    "today",
    "oneToThreeDays",
    "fourPlusDays",
  ]),
  didHeRespond: z.enum(["yes", "no", "sortOf", "noQuestion"]),
  // Optional free text — bounded to keep prompts small and cheap.
  additionalNotes: z.string().max(500),
});
export type QuickContext = z.infer<typeof QuickContextSchema>;

// Swift's SE-0295 Codable synthesis for `enum ContextInput { case
// conversation(String); case quick(QuickContext) }` encodes a single-key
// object keyed by the case name.
export const ContextInputSchema = z.union([
  z.object({ conversation: z.string().max(8000) }),
  z.object({ quick: QuickContextSchema }),
]);
export type ContextInput = z.infer<typeof ContextInputSchema>;

export const JudgmentRequestSchema = z.object({
  proposedMessage: z.string().min(1).max(2000),
  goal: GoalSchema,
  context: ContextInputSchema,
});
export type JudgmentRequestPayload = z.infer<typeof JudgmentRequestSchema>;

/**
 * The strict structured output the model must return. Matches the
 * product brief's conceptual JSON exactly (snake_case, matching the
 * Swift client's `RemoteJudgmentResponseDTO` wire mapping in
 * RemoteAIJudgmentProvider.swift).
 */
export const JudgmentResponseSchema = z.object({
  verdict: z.enum(["send", "rewrite", "sleep", "dont_send"]),
  reason: z.string().min(1).max(400),
  recommended_action: z.enum(["send", "wait", "rewrite", "direct"]),
  rewrite_options: z.array(z.string().min(1).max(300)).max(3),
});
export type JudgmentResponsePayload = z.infer<typeof JudgmentResponseSchema>;
