/**
 * Central environment configuration. No Anthropic/OpenAI/hosted-provider
 * API key exists anywhere in this codebase — `LOCAL_LLM_API_KEY` is
 * optional and, when set, is a credential for reaching your OWN
 * self-hosted inference server privately, not a third-party API key.
 */

const NODE_ENV = process.env.NODE_ENV ?? "development";
const isProduction = NODE_ENV === "production";

function readEnv(name: string): string | undefined {
  const value = process.env[name];
  return value && value.trim().length > 0 ? value : undefined;
}

function required(name: string, devDefault?: string): string {
  const value = readEnv(name);
  if (value !== undefined) return value;
  if (!isProduction && devDefault !== undefined) return devDefault;
  throw new Error(
    `Missing required environment variable: ${name}` +
      (isProduction ? "" : ` (no dev default configured for this variable)`),
  );
}

function positiveInt(name: string, fallback: number, allowZero = false): number {
  const raw = readEnv(name);
  if (raw === undefined) return fallback;
  const parsed = Number.parseInt(raw, 10);
  const minimum = allowZero ? 0 : 1;
  if (!Number.isFinite(parsed) || parsed < minimum) {
    throw new Error(`${name} must be an integer >= ${minimum}`);
  }
  return parsed;
}

function parseBaseUrl(raw: string): string {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new Error("LOCAL_LLM_BASE_URL must be a valid absolute URL");
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("LOCAL_LLM_BASE_URL must use http or https");
  }
  return raw.replace(/\/+$/, "");
}

function isLoopbackUrl(url: string): boolean {
  const host = new URL(url).hostname;
  return host === "localhost" || host === "127.0.0.1" || host === "::1";
}

const localLlmBaseUrl = parseBaseUrl(
  required("LOCAL_LLM_BASE_URL", "http://127.0.0.1:8080/v1"),
);

if (isProduction && isLoopbackUrl(localLlmBaseUrl)) {
  throw new Error(
    "Refusing to start with NODE_ENV=production and a localhost/127.0.0.1 LOCAL_LLM_BASE_URL. " +
      "Set LOCAL_LLM_BASE_URL to the private network address of your self-hosted inference " +
      "server (for example a Docker Compose service name or private/VPN address).",
  );
}

export const config = {
  nodeEnv: NODE_ENV,
  isProduction,
  port: positiveInt("PORT", 3000),

  localLlm: {
    baseUrl: localLlmBaseUrl,
    model: required("LOCAL_LLM_MODEL", "qwen3:4b"),
    apiKey: readEnv("LOCAL_LLM_API_KEY"),
    timeoutMs: positiveInt("LOCAL_LLM_TIMEOUT_MS", 20000),
  },

  maxBodyBytes: positiveInt("MAX_BODY_BYTES", 20000),

  rateLimit: {
    windowMs: positiveInt("RATE_LIMIT_WINDOW_MS", 60000),
    max: positiveInt("RATE_LIMIT_MAX", 30),
  },

  // Number of reverse-proxy hops Express should trust when resolving req.ip.
  // `true` is intentionally not supported because an unrestricted trust chain
  // lets a direct caller spoof X-Forwarded-For and bypass IP rate limiting.
  trustProxyHops: positiveInt("TRUST_PROXY_HOPS", 1, true),

  publicClientToken: readEnv("APP_CLIENT_TOKEN"),
};
