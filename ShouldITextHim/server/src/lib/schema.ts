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
 *
 * `need_context` / `add_context` are first-class, not error states: a
 * local model that doesn't have enough information to responsibly judge
 * tone, goal fit, or context should say so rather than guess. Absence of
 * a detected problem is never treated as evidence for `send` — see
 * `prompt.ts` and `../../AI_SAFETY.md`.
 */
export const JudgmentResponseSchema = z.object({
  verdict: z.enum(["send", "rewrite", "sleep", "dont_send", "need_context"]),
  reason: z.string().min(1).max(400),
  recommended_action: z.enum(["send", "wait", "rewrite", "direct", "add_context"]),
  rewrite_options: z.array(z.string().min(1).max(300)).max(3),
});
export type JudgmentResponsePayload = z.infer<typeof JudgmentResponseSchema>;

/**
 * The raw JSON Schema (not a Zod schema) sent to the local inference
 * server's OpenAI-compatible `response_format: { type: "json_schema" }`
 * field, for servers that support constrained/grammar-guided decoding
 * (llama.cpp server, and Ollama's OpenAI-compatible endpoint where
 * practical). Hand-kept in sync with `JudgmentResponseSchema` above —
 * there are only four fields, so this is not a maintenance burden.
 * Servers that ignore `response_format` entirely still work: the system
 * prompt instructs the same shape in plain language, and every response
 * is re-validated against `JudgmentResponseSchema` regardless.
 */
export const JUDGMENT_RESPONSE_JSON_SCHEMA = {
  type: "object",
  properties: {
    verdict: {
      type: "string",
      enum: ["send", "rewrite", "sleep", "dont_send", "need_context"],
    },
    reason: { type: "string" },
    recommended_action: {
      type: "string",
      enum: ["send", "wait", "rewrite", "direct", "add_context"],
    },
    rewrite_options: {
      type: "array",
      items: { type: "string" },
    },
  },
  required: ["verdict", "reason", "recommended_action", "rewrite_options"],
  additionalProperties: false,
} as const;
