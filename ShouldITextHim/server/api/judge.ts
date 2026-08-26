import type { VercelRequest, VercelResponse } from "@vercel/node";
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { JudgmentRequestSchema, JudgmentResponseSchema } from "../lib/schema.js";
import { buildSystemPrompt, buildUserPrompt } from "../lib/prompt.js";

// Reads ANTHROPIC_API_KEY from the environment — set as a Vercel project
// environment variable, never committed to source. See ../README.md.
const client = new Anthropic();

const MAX_BODY_BYTES = 20_000;
const REQUEST_TIMEOUT_MS = 9_000;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== "POST") {
    res.status(405).json({ error: "method_not_allowed" });
    return;
  }

  // Defense in depth on top of Vercel's own platform body-size limit —
  // this app never needs a request anywhere near this size.
  const rawBody = typeof req.body === "string" ? req.body : JSON.stringify(req.body ?? {});
  if (Buffer.byteLength(rawBody, "utf8") > MAX_BODY_BYTES) {
    res.status(413).json({ error: "payload_too_large" });
    return;
  }

  const parsedRequest = JudgmentRequestSchema.safeParse(req.body);
  if (!parsedRequest.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }
  const input = parsedRequest.data;

  try {
    const response = await client.messages.parse(
      {
        model: "claude-opus-5",
        max_tokens: 4096,
        output_config: {
          effort: "low",
          format: zodOutputFormat(JudgmentResponseSchema),
        },
        system: buildSystemPrompt(),
        messages: [{ role: "user", content: buildUserPrompt(input) }],
      },
      { timeout: REQUEST_TIMEOUT_MS },
    );

    if (!response.parsed_output) {
      res.status(502).json({ error: "model_output_invalid" });
      return;
    }

    // Belt-and-suspenders: re-validate even though output_config.format
    // already constrains the model's response. The client independently
    // validates again on receipt — see RemoteAIJudgmentProvider.swift.
    const validated = JudgmentResponseSchema.safeParse(response.parsed_output);
    if (!validated.success) {
      res.status(502).json({ error: "model_output_invalid" });
      return;
    }

    res.status(200).json(validated.data);
  } catch (err) {
    // Never log request/response content (proposed messages, pasted
    // conversations, or context notes) — see PRIVACY_DATA_MAP.md. Only
    // the error type/name is logged. Most-specific first, per Anthropic's
    // documented TypeScript error hierarchy (APIConnectionError is a
    // subclass of APIError, so it must be checked first).
    if (err instanceof Anthropic.RateLimitError) {
      console.error("judge_error: rate_limited");
      res.status(429).json({ error: "rate_limited" });
    } else if (err instanceof Anthropic.APIConnectionError) {
      // Covers network failures and request timeouts (the {timeout}
      // request option surfaces here, not as a distinct exception type).
      console.error("judge_error: connection_or_timeout");
      res.status(504).json({ error: "timeout" });
    } else if (err instanceof Anthropic.APIError) {
      console.error("judge_error: anthropic_api_error", err.status);
      res.status(502).json({ error: "model_unavailable" });
    } else {
      console.error("judge_error: internal", err instanceof Error ? err.name : "unknown");
      res.status(500).json({ error: "internal_error" });
    }
  }
}
