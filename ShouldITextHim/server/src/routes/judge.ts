import { Router, type Request, type Response } from "express";
import { JudgmentRequestSchema, JudgmentResponseSchema } from "../lib/schema.js";
import { buildSystemPrompt, buildUserPrompt } from "../lib/prompt.js";
import {
  requestLocalJudgment,
  extractJsonObject,
  LocalInferenceError,
  LocalInferenceTimeoutError,
} from "../lib/localInferenceClient.js";
import { config } from "../lib/config.js";
import { checkRateLimit } from "../lib/rateLimiter.js";

export const judgeRouter = Router();

judgeRouter.post("/judge", async (req: Request, res: Response) => {
  const clientKey = req.ip ?? "unknown";
  if (!checkRateLimit(clientKey, config.rateLimit.windowMs, config.rateLimit.max)) {
    res.status(429).json({ error: "rate_limited" });
    return;
  }

  const parsedRequest = JudgmentRequestSchema.safeParse(req.body);
  if (!parsedRequest.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }
  const input = parsedRequest.data;

  try {
    // NEVER log request content (proposed message, pasted conversation,
    // or context notes) anywhere in this handler — see PRIVACY_DATA_MAP.md.
    const { content } = await requestLocalJudgment(
      config.localLlm,
      buildSystemPrompt(),
      buildUserPrompt(input),
    );

    let parsedJson: unknown;
    try {
      parsedJson = JSON.parse(extractJsonObject(content));
    } catch {
      console.error("judge_error: model_output_not_json");
      res.status(502).json({ error: "model_output_invalid" });
      return;
    }

    // The app must never display arbitrary free-form model output
    // without schema validation — reject anything that doesn't match
    // exactly, even if the inference server's constrained decoding was
    // supposed to guarantee it. The client independently re-validates
    // again on receipt — see RemoteAIJudgmentProvider.swift.
    const validated = JudgmentResponseSchema.safeParse(parsedJson);
    if (!validated.success) {
      console.error("judge_error: model_output_failed_schema_validation");
      res.status(502).json({ error: "model_output_invalid" });
      return;
    }

    res.status(200).json(validated.data);
  } catch (err) {
    if (err instanceof LocalInferenceTimeoutError) {
      console.error("judge_error: timeout");
      res.status(504).json({ error: "timeout" });
    } else if (err instanceof LocalInferenceError) {
      console.error("judge_error: inference_unavailable");
      res.status(502).json({ error: "model_unavailable" });
    } else {
      console.error("judge_error: internal", err instanceof Error ? err.name : "unknown");
      res.status(500).json({ error: "internal_error" });
    }
  }
});
