import { Router, type Request, type Response } from "express";
import { config } from "../lib/config.js";
import { checkRateLimit } from "../lib/rateLimiter.js";
import { extractJsonObject, InferenceError, InferenceTimeoutError, requestStructuredInference } from "../lib/inference.js";
import { getAppDefinition, listApps } from "../apps/registry.js";

export const gatewayRouter = Router();

async function execute(appId: string, task: string, req: Request, res: Response): Promise<void> {
  const app = getAppDefinition(appId, task);
  if (!app) {
    res.status(404).json({ error: "unknown_app_or_task" });
    return;
  }

  const clientKey = `${appId}:${req.ip ?? "unknown"}`;
  if (!checkRateLimit(clientKey, config.rateLimit.windowMs, config.rateLimit.max)) {
    res.status(429).json({ error: "rate_limited" });
    return;
  }

  const parsed = app.requestSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }

  try {
    // Never log body content. App inputs may contain private user text.
    const raw = await requestStructuredInference(config.localLlm, {
      systemPrompt: app.buildSystemPrompt(),
      userPrompt: app.buildUserPrompt(parsed.data),
      jsonSchema: app.responseJsonSchema,
      schemaName: app.schemaName,
      model: app.model,
      temperature: app.temperature,
      maxTokens: app.maxTokens,
    });

    let decoded: unknown;
    try {
      decoded = JSON.parse(extractJsonObject(raw));
    } catch {
      res.status(502).json({ error: "model_output_invalid" });
      return;
    }

    const validated = app.responseSchema.safeParse(decoded);
    if (!validated.success) {
      res.status(502).json({ error: "model_output_invalid" });
      return;
    }
    res.status(200).json(validated.data);
  } catch (error) {
    if (error instanceof InferenceTimeoutError) {
      res.status(504).json({ error: "timeout" });
    } else if (error instanceof InferenceError) {
      res.status(502).json({ error: "model_unavailable" });
    } else {
      console.error("gateway_error:", error instanceof Error ? error.name : "unknown");
      res.status(500).json({ error: "internal_error" });
    }
  }
}

gatewayRouter.get("/apps", (_req, res) => res.status(200).json({ apps: listApps() }));
gatewayRouter.post("/apps/:appId/:task", async (req, res) => execute(req.params.appId, req.params.task, req, res));

// Backward-compatible Day 1 route while the iOS client migrates to the shared URL.
gatewayRouter.post("/legacy/should-i-text-him/judge", async (req, res) => execute("should-i-text-him", "judge", req, res));
