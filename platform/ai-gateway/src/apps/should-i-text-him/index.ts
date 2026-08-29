import type { GatewayAppDefinition } from "../types.js";
import { JudgmentRequestSchema, JudgmentResponseSchema, JUDGMENT_RESPONSE_JSON_SCHEMA } from "./schema.js";
import { buildSystemPrompt, buildUserPrompt } from "./prompt.js";

export const shouldITextHimApp: GatewayAppDefinition = {
  id: "should-i-text-him",
  task: "judge",
  requestSchema: JudgmentRequestSchema,
  responseSchema: JudgmentResponseSchema,
  responseJsonSchema: JUDGMENT_RESPONSE_JSON_SCHEMA,
  schemaName: "should_i_text_him_judgment",
  buildSystemPrompt,
  buildUserPrompt,
  model: process.env.SHOULD_I_TEXT_HIM_MODEL?.trim() || undefined,
  temperature: 0.2,
  maxTokens: 600,
};
