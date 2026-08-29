const NODE_ENV = process.env.NODE_ENV ?? "development";
const isProduction = NODE_ENV === "production";

function readEnv(name: string): string | undefined {
  const value = process.env[name];
  return value && value.trim().length > 0 ? value.trim() : undefined;
}

function required(name: string, devDefault?: string): string {
  const value = readEnv(name);
  if (value !== undefined) return value;
  if (!isProduction && devDefault !== undefined) return devDefault;
  throw new Error(`Missing required environment variable: ${name}`);
}

function positiveInt(name: string, fallback: number, allowZero = false): number {
  const raw = readEnv(name);
  if (raw === undefined) return fallback;
  const parsed = Number.parseInt(raw, 10);
  const minimum = allowZero ? 0 : 1;
  if (!Number.isFinite(parsed) || parsed < minimum) throw new Error(`${name} must be an integer >= ${minimum}`);
  return parsed;
}

function parseBaseUrl(raw: string): string {
  const url = new URL(raw);
  if (url.protocol !== "http:" && url.protocol !== "https:") throw new Error("LOCAL_LLM_BASE_URL must use http or https");
  return raw.replace(/\/+$/, "");
}

const baseUrl = parseBaseUrl(required("LOCAL_LLM_BASE_URL", "http://127.0.0.1:11434/v1"));
const hostname = new URL(baseUrl).hostname;
if (isProduction && ["localhost", "127.0.0.1", "::1"].includes(hostname)) {
  throw new Error("Production LOCAL_LLM_BASE_URL must point to a private/reachable inference host, not loopback.");
}

export const config = {
  nodeEnv: NODE_ENV,
  isProduction,
  port: positiveInt("PORT", 3000),
  maxBodyBytes: positiveInt("MAX_BODY_BYTES", 20000),
  trustProxyHops: positiveInt("TRUST_PROXY_HOPS", 1, true),
  rateLimit: {
    windowMs: positiveInt("RATE_LIMIT_WINDOW_MS", 60000),
    max: positiveInt("RATE_LIMIT_MAX", 30),
  },
  localLlm: {
    baseUrl,
    defaultModel: required("LOCAL_LLM_MODEL", "qwen3:4b"),
    apiKey: readEnv("LOCAL_LLM_API_KEY"),
    timeoutMs: positiveInt("LOCAL_LLM_TIMEOUT_MS", 20000),
  },
};
