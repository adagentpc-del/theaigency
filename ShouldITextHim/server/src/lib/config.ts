/**
 * Central environment configuration. No Anthropic/OpenAI/hosted-provider
 * API key exists anywhere in this codebase — `LOCAL_LLM_API_KEY` is
 * optional and, when set, is a credential for reaching your OWN
 * self-hosted inference server privately, not a third-party API key.
 *
 * The one hard rule enforced here, not just documented: this process
 * refuses to start in production pointed at a localhost/loopback
 * inference URL, so a bare `vercel dev`-style default can never
 * accidentally ship as the production backend. See `../../README.md` →
 * "Local development vs. production" for the two supported modes.
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

function isLoopbackUrl(url: string): boolean {
  try {
    const host = new URL(url).hostname;
    return host === "localhost" || host === "127.0.0.1" || host === "::1";
  } catch {
    // Not a parseable URL at all — let the caller's own validation catch it;
    // this check only cares about accidentally-shipped loopback addresses.
    return false;
  }
}

const localLlmBaseUrl = required("LOCAL_LLM_BASE_URL", "http://127.0.0.1:8080/v1");

if (isProduction && isLoopbackUrl(localLlmBaseUrl)) {
  throw new Error(
    "Refusing to start with NODE_ENV=production and a localhost/127.0.0.1 LOCAL_LLM_BASE_URL. " +
      "Set LOCAL_LLM_BASE_URL to the private network address of your self-hosted inference " +
      "server (e.g. a Docker Compose service name, or a private/VPN address) — never a loopback " +
      "address in production. See README.md → 'Local development vs. production'.",
  );
}

export const config = {
  nodeEnv: NODE_ENV,
  isProduction,
  port: parseInt(readEnv("PORT") ?? "3000", 10),

  localLlm: {
    baseUrl: localLlmBaseUrl,
    // Never hard-coded into application logic — this is the only place
    // the model name is read, and every request uses whatever this
    // resolves to at startup.
    model: required("LOCAL_LLM_MODEL", "qwen3:4b"),
    // Optional. Most local llama.cpp/Ollama deployments don't require an
    // API key at all; when one is configured (e.g. a reverse proxy in
    // front of the inference server expects a bearer token), it is a
    // credential for OUR OWN private infrastructure, never a third-party
    // hosted-provider key.
    apiKey: readEnv("LOCAL_LLM_API_KEY"),
    timeoutMs: parseInt(readEnv("LOCAL_LLM_TIMEOUT_MS") ?? "20000", 10),
  },

  maxBodyBytes: parseInt(readEnv("MAX_BODY_BYTES") ?? "20000", 10),

  rateLimit: {
    windowMs: parseInt(readEnv("RATE_LIMIT_WINDOW_MS") ?? "60000", 10),
    max: parseInt(readEnv("RATE_LIMIT_MAX") ?? "30", 10),
  },

  // Optional, non-secret application identifier a client may send (e.g. a
  // header). Since it ships inside the iOS binary it can be read out of
  // the app and is never treated as a secret or as the sole access
  // control — see SECURITY_REVIEW.md.
  publicClientToken: readEnv("APP_CLIENT_TOKEN"),
};
