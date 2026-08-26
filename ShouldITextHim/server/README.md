# Judgment Server — Should I Text Him?

The application API that sits between the iOS app and a **self-hosted local language model**. This project has never used, and does not use, any third-party hosted-AI provider (Anthropic, OpenAI, or otherwise) — there is no such API key anywhere in this codebase. See `../DECISIONS.md` decision 18 for why, and `../API_CONTRACT.md` for the full wire contract.

## Target architecture

```
iOS App
    ↓ HTTPS
Secure ShouldITextHim API   (this project)
    ↓ private/local connection
Self-hosted inference server   (llama.cpp server or Ollama)
    ↓
Local model   (e.g. qwen3:8b, qwen3:4b, llama3.2:3b)
```

The iOS app **never** connects to the inference server (llama.cpp/Ollama) directly — it only ever knows this API's public `/api/judge` URL. This API, in turn, talks to the inference server over a private/local connection that must never be exposed to the public internet on its own (see "Security" below).

## What it does

1. Receives `{ proposedMessage, goal, context }` (exact shape: `src/lib/schema.ts` → `JudgmentRequestSchema`).
2. Validates it strictly (Zod) and rate-limits the caller — rejects anything malformed, oversized, or over-limit before it ever reaches the model.
3. Calls your configured local inference server's OpenAI-compatible `/v1/chat/completions` endpoint (`src/lib/localInferenceClient.ts`) with a fixed system prompt (`src/lib/prompt.ts`) and, where the server supports it, constrained/schema-guided JSON output.
4. Parses and strictly re-validates the model's output against the exact response schema — malformed JSON, a missing field, or an out-of-enum value is rejected, never passed through.
5. Returns `{ verdict, reason, recommended_action, rewrite_options }` as JSON. The client independently re-validates again on receipt — see `../ShouldITextHim/Engine/RemoteAIJudgmentProvider.swift`.

## What it deliberately does NOT do

- **No logging of request or response content.** Every log line in this codebase is an error *type* string (e.g. `"judge_error: timeout"`), never the proposed message, pasted conversation, context notes, or the model's output.
- **No persistence.** Nothing is written to a database or file between requests — a request's content exists only in memory for that one request/response cycle.
- **No generic error detail returned to the client.** Every failure path returns a small, fixed `{ error: "..." }` shape — never a stack trace or internal exception message.

## Local development vs. production

|  | Local development | Production |
|---|---|---|
| Inference server | Runs on your machine (`llama.cpp server` or `ollama serve`), reachable at `http://127.0.0.1:...` | Runs on your private infrastructure, reachable only over a private network/VPN/Docker-internal network — **never** a public address |
| `LOCAL_LLM_BASE_URL` | `http://127.0.0.1:8080/v1` (llama.cpp) or `http://127.0.0.1:11434/v1` (Ollama) | The inference server's private network address (e.g. `http://ollama:11434/v1` inside Docker Compose, or a VPN-only hostname) |
| `NODE_ENV` | unset or `development` | `production` |
| iOS app points at | `http://<your-LAN-IP>:3000/api/judge` (pass a custom `endpoint` to `RemoteAIJudgmentProvider.init` for local testing) | Your real deployed HTTPS URL |

**`lib/config.ts` enforces this, not just documents it**: if `NODE_ENV=production` and `LOCAL_LLM_BASE_URL` is a `localhost`/`127.0.0.1` address, the process refuses to start. This exists specifically so a `vercel dev`-style local default can never accidentally ship as the production backend.

### Running locally

1. **Start an inference server.** Either:
   - [llama.cpp server](https://github.com/ggml-org/llama.cpp): `llama-server -m <path-to-a-GGUF-model> --port 8080`
   - [Ollama](https://ollama.com): `ollama serve`, then `ollama pull qwen3:4b` (or whichever model you're testing)
2. `cp .env.example .env` and fill in `LOCAL_LLM_BASE_URL` / `LOCAL_LLM_MODEL` for whichever you chose.
3. `npm install`
4. `npm run dev` — runs the API with hot reload at `http://localhost:3000`.
5. Point a local build of the iOS app at `http://<your-LAN-IP>:3000/api/judge` by passing a custom `endpoint` to `RemoteAIJudgmentProvider.init` (a physical device can't reach `localhost` on your Mac — use your machine's LAN IP; the Simulator can use `localhost` directly).

### Deploying to production

This is a normal, small, stateful Node process (not a serverless function) — deploy it however you'd deploy any small Node service. Two supported paths:

**Docker Compose (recommended for a single-box deployment):**

1. Copy `docker-compose.example.yml` to `docker-compose.yml`, adjust `LOCAL_LLM_MODEL` to whatever your benchmark (see "Model benchmark harness" below) selected.
2. `docker compose up -d --build`.
3. Put a reverse proxy / TLS terminator (Caddy, nginx, Cloudflare Tunnel, etc.) in front of the `api` service's port — this project does not terminate TLS itself, since the right choice depends on your hosting environment. **Never expose the `ollama`/inference-server port directly** — the example compose file only exposes it on the internal Docker network (`expose`, not `ports`), reachable solely by the `api` service.
4. Set `RemoteAIJudgmentProvider.defaultEndpoint` in the iOS client to your real HTTPS URL (see `../FOUNDER_ACTION_REQUIRED.md`).

**Bare metal / VM (systemd, or any process manager):**

1. Run your inference server bound to a private/loopback interface only (never `0.0.0.0` on a public interface).
2. `npm install --omit=dev && npm run build`, then run `node dist/server.js` under a process manager (systemd, pm2, etc.) with `NODE_ENV=production` and `LOCAL_LLM_BASE_URL` pointing at the inference server's private address.
3. Put this process behind a reverse proxy/TLS terminator, same as above — do not expose the raw Node process directly to the internet.

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `LOCAL_LLM_BASE_URL` | Yes (has a dev-only default) | Your inference server's OpenAI-compatible base URL, e.g. `http://127.0.0.1:8080/v1` |
| `LOCAL_LLM_MODEL` | Yes (has a dev-only default) | Model name/tag as your inference server identifies it (e.g. `qwen3:4b`). **Never hard-coded** into application code — this is the only place it's read. |
| `LOCAL_LLM_API_KEY` | No | Only needed if you've put your own auth in front of your inference server. A credential for **your own infrastructure**, never a third-party provider. |
| `LOCAL_LLM_TIMEOUT_MS` | No (default `20000`) | Per-request timeout to the inference server. |
| `NODE_ENV` | No (default `development`) | Set to `production` for real deployments — enables the localhost-endpoint guard above. |
| `PORT` | No (default `3000`) | Port this API listens on. |
| `MAX_BODY_BYTES` | No (default `20000`) | Request body size cap. |
| `RATE_LIMIT_WINDOW_MS` / `RATE_LIMIT_MAX` | No (default `60000` / `30`) | Basic per-IP rate limit — see "Security" below. |
| `APP_CLIENT_TOKEN` | No | Optional, non-secret app-identifying value (see "Security"). |

## Security

- **HTTPS** — terminated by your reverse proxy in front of this process (see "Deploying to production"); this app itself speaks plain HTTP, by design, since TLS termination is an infrastructure concern that depends on your hosting choice.
- **Payload-size limits** — `MAX_BODY_BYTES` (default 20KB), enforced by `express.json({ limit })`; oversized bodies are rejected with `400` before touching any handler logic.
- **Request timeouts** — every call to the inference server has a hard timeout (`LOCAL_LLM_TIMEOUT_MS`); a hung inference server can't hang this process's request handling.
- **Schema validation, both directions** — the incoming request and the model's output are both validated against exact Zod schemas (`src/lib/schema.ts`); the app never displays arbitrary free-form model output.
- **Basic IP-based rate limiting** (`src/lib/rateLimiter.ts`) — a real, in-memory, per-IP fixed-window limiter. IP-based, not device- or account-based, because this app has no accounts and must never collect a device/advertising identifier (see `../PRIVACY_DATA_MAP.md`). Honestly scoped: this is a real limiter for a single long-running process, not a distributed one — running multiple replicas means each enforces its own independent limit. See "Known limitations" below.
- **No raw conversation logging, no prompt/content persistence** — verified by code review of every log call site in this project (`grep -rn "console\." src/` — none interpolates request/response content).
- **Generic user-facing errors, no internal stack traces** — every error path returns a small fixed `{ error: "..." }` JSON body; `src/server.ts`'s error handler never serializes an exception to the client.
- **Optional public client token** (`APP_CLIENT_TOKEN`) — if you choose to have the iOS app send an app-identifying header, treat it as **non-secret**: it ships inside the app binary and can be extracted, so it can help distinguish "this app" traffic from generic internet noise but must never be the sole access control. This project does not require one by default.

**Do not expose the inference server publicly.** `llama.cpp server`/`ollama serve` have no meaningful authentication or input validation of their own — they exist to be called by trusted infrastructure, not by arbitrary internet traffic. The whole point of this API layer is to be the only public surface; see the architecture diagram above.

## Known limitations (documented, not hidden)

- **Rate limiting is single-instance and in-memory** — real distributed rate limiting across multiple replicas needs a shared store (Redis/Upstash); that's disproportionate infrastructure for this app's current scale and is tracked as a `../POST_LAUNCH.md` item, not silently skipped.
- **No request authentication beyond the optional, non-secret `APP_CLIENT_TOKEN`** — Apple's DeviceCheck/App Attest would be a stronger option if abuse becomes a real problem; also tracked in `../POST_LAUNCH.md`.
- **Local model judgment quality depends entirely on which model you deploy** — this is the whole reason the benchmark harness below exists. Do not deploy a model that hasn't passed it.

## Model benchmark harness

`scripts/benchmark.ts` runs the same 60 adversarial fixtures the iOS test suite uses (`../ShouldITextHimTests/AdversarialSemanticFixtures.swift`, mirrored in wire format at `benchmark/fixtures.json`) against a configured model, using the exact same prompt/schema/client code the live `/api/judge` route uses — so a benchmark result is a real signal about what that model would actually do in production, not a separate simulation.

```bash
npm run benchmark -- --model qwen3:8b --base-url http://127.0.0.1:11434/v1
npm run benchmark -- --model qwen3:4b
npm run benchmark -- --model llama3.2:3b
```

Model and base URL are also configurable via `LOCAL_LLM_MODEL`/`LOCAL_LLM_BASE_URL` environment variables — CLI flags take precedence — so you can benchmark several candidate models back to back with no code changes.

The report (printed to the console and written to `benchmark-results/<model>-<timestamp>.json`, gitignored) includes: total fixtures, acceptable verdict rate, unacceptable verdict count, SEND IT false-positive count, critical safety failures (a heuristic text scan for the specific "never" list in the system prompt — see the comment in `scripts/benchmark.ts` for exactly what it checks and its limits), malformed-response count (split into schema failures vs. unreachable-server failures), average and p95 latency, and average completion tokens (when the inference server reports usage).

### Documented product-quality threshold

A model is production-ready only if **all** of the following hold:

| Metric | Threshold |
|---|---|
| Acceptable verdict rate | ≥ 95% |
| Critical safety failures | 0 |
| SEND IT false positives (hostile-message SEND IT failures) | 0 |
| Malformed responses (incl. unreachable/timeout) | < 1% |

**Do not select a model based solely on speed.** The winning model is the smallest one that clears this threshold — run the benchmark against every candidate on your inference machine (`qwen3:8b`, `qwen3:4b`, `llama3.2:3b`, or others) and pick the smallest passer, not the fastest or the biggest. `scripts/benchmark.ts` exits with status `1` when a run fails the threshold, so it's safe to gate a deploy script on it.

No model has been benchmarked against a real deployed inference server in this build environment — this sandbox has no GPU and no running llama.cpp/Ollama instance. Running this harness for real, on your inference hardware, is listed as a required step in `../FOUNDER_ACTION_REQUIRED.md`.

## Cost

None per request — this is the entire reason for moving off a hosted-AI provider. The only ongoing cost is whatever compute you already run the inference server on (or a one-time cost if you provision new hardware for it). Latency and quality both depend on the model size you choose, which is exactly what the benchmark above exists to make an evidence-based decision about rather than a guess.
