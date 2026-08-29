export interface InferenceConfig {
  baseUrl: string;
  defaultModel: string;
  apiKey?: string;
  timeoutMs: number;
}

export interface StructuredInferenceRequest {
  systemPrompt: string;
  userPrompt: string;
  jsonSchema: Record<string, unknown>;
  schemaName: string;
  model?: string;
  temperature?: number;
  maxTokens?: number;
}

export class InferenceError extends Error {}
export class InferenceTimeoutError extends InferenceError {}

export async function requestStructuredInference(cfg: InferenceConfig, input: StructuredInferenceRequest): Promise<string> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), cfg.timeoutMs);
  try {
    let response: Response;
    try {
      response = await fetch(`${cfg.baseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(cfg.apiKey ? { Authorization: `Bearer ${cfg.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: input.model ?? cfg.defaultModel,
          temperature: input.temperature ?? 0.2,
          max_tokens: input.maxTokens ?? 600,
          messages: [
            { role: "system", content: input.systemPrompt },
            { role: "user", content: input.userPrompt },
          ],
          response_format: {
            type: "json_schema",
            json_schema: { name: input.schemaName, strict: true, schema: input.jsonSchema },
          },
        }),
        signal: controller.signal,
      });
    } catch (error) {
      if (error instanceof Error && error.name === "AbortError") throw new InferenceTimeoutError("timeout");
      throw new InferenceError("inference_unreachable");
    }
    if (!response.ok) throw new InferenceError(`inference_http_${response.status}`);
    const body = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
    const content = body.choices?.[0]?.message?.content;
    if (!content) throw new InferenceError("inference_empty_response");
    return content;
  } finally {
    clearTimeout(timeout);
  }
}

export function extractJsonObject(raw: string): string {
  const first = raw.indexOf("{");
  const last = raw.lastIndexOf("}");
  return first >= 0 && last >= first ? raw.slice(first, last + 1) : raw;
}
