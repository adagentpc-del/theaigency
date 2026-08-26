import { JUDGMENT_RESPONSE_JSON_SCHEMA } from "./schema.js";

/**
 * Provider-neutral client for an OpenAI-compatible local inference
 * server — llama.cpp server's `/v1/chat/completions`, or Ollama's
 * OpenAI-compatible endpoint (`http://<host>:11434/v1`). This is the
 * ONLY place that talks to the inference server; the model name and
 * base URL are read once from config and never hard-coded here.
 *
 * This app never calls a third-party hosted-model API — everything this
 * function talks to is infrastructure operated for this app (see
 * ../../README.md's architecture diagram).
 */

export interface LocalInferenceConfig {
  baseUrl: string;
  model: string;
  apiKey?: string;
  timeoutMs: number;
}

export interface LocalInferenceResult {
  /** Raw text content from the model — NOT yet parsed/validated as JSON. */
  content: string;
  latencyMs: number;
  completionTokens?: number;
}

export class LocalInferenceError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "LocalInferenceError";
  }
}

export class LocalInferenceTimeoutError extends LocalInferenceError {
  constructor() {
    super("local_inference_timeout");
    this.name = "LocalInferenceTimeoutError";
  }
}

interface OpenAIChatCompletionResponse {
  choices?: Array<{ message?: { content?: string } }>;
  usage?: { completion_tokens?: number };
}

export async function requestLocalJudgment(
  inference: LocalInferenceConfig,
  systemPrompt: string,
  userPrompt: string,
): Promise<LocalInferenceResult> {
  const controller = new AbortController();
  const timeoutHandle = setTimeout(() => controller.abort(), inference.timeoutMs);
  const startedAt = Date.now();

  try {
    let response: Response;
    try {
      response = await fetch(`${inference.baseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(inference.apiKey ? { Authorization: `Bearer ${inference.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: inference.model,
          temperature: 0.2,
          max_tokens: 600,
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: userPrompt },
          ],
          // Constrained/structured output where the inference server
          // supports it (llama.cpp server, and Ollama's OpenAI-compatible
          // endpoint where practical). A server that doesn't recognize
          // this field typically ignores it rather than erroring, and
          // the system prompt independently instructs the same JSON
          // shape — every response is re-validated regardless, so this
          // is a quality aid, not something correctness depends on.
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "judgment_result",
              strict: true,
              schema: JUDGMENT_RESPONSE_JSON_SCHEMA,
            },
          },
        }),
        signal: controller.signal,
      });
    } catch (err) {
      if (err instanceof Error && err.name === "AbortError") {
        throw new LocalInferenceTimeoutError();
      }
      throw new LocalInferenceError("local_inference_unreachable");
    }

    const latencyMs = Date.now() - startedAt;

    if (!response.ok) {
      throw new LocalInferenceError(`local_inference_http_${response.status}`);
    }

    let body: OpenAIChatCompletionResponse;
    try {
      body = (await response.json()) as OpenAIChatCompletionResponse;
    } catch {
      throw new LocalInferenceError("local_inference_invalid_json_envelope");
    }

    const content = body.choices?.[0]?.message?.content;
    if (typeof content !== "string" || content.trim().length === 0) {
      throw new LocalInferenceError("local_inference_empty_response");
    }

    return { content, latencyMs, completionTokens: body.usage?.completion_tokens };
  } finally {
    clearTimeout(timeoutHandle);
  }
}

/**
 * Small local models are more prone than large hosted models to wrapping
 * their JSON in prose or a markdown code fence despite instructions.
 * Extracts the first balanced-looking `{...}` object from the raw
 * content before handing it to `JSON.parse` + schema validation, so a
 * stray "Sure, here's the JSON:" prefix doesn't turn a good judgment
 * into a malformed-response failure. This is a resilience aid only — the
 * extracted text still goes through full JSON parsing and strict schema
 * validation in `routes/judge.ts`; nothing here weakens that.
 */
export function extractJsonObject(rawContent: string): string {
  const firstBrace = rawContent.indexOf("{");
  const lastBrace = rawContent.lastIndexOf("}");
  if (firstBrace === -1 || lastBrace === -1 || lastBrace < firstBrace) {
    return rawContent;
  }
  return rawContent.slice(firstBrace, lastBrace + 1);
}
