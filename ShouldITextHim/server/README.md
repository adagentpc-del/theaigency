# Judgment Server — Should I Text Him?

A single serverless endpoint, `POST /api/judge`, that holds the model provider's API key server-side and returns strict structured judgment JSON to the iOS client. This is the "smallest secure endpoint needed for this app" — see `../DECISIONS.md` and `../API_CONTRACT.md` for why it exists and how the client talks to it.

**Nothing about this endpoint is secret except the environment variable holding the API key.** The endpoint URL itself is public and safe to embed in the client — that's the whole point of the client/server split described in the Day 1 product brief: *never put the model API key in the iOS binary.*

## What it does

1. Receives `{ proposedMessage, goal, context }` (exact shape: `lib/schema.ts` → `JudgmentRequestSchema`).
2. Validates it strictly (Zod) — rejects anything malformed or oversized before it ever reaches the model.
3. Calls the Claude Messages API (`claude-opus-5`) with a fixed system prompt (`lib/prompt.ts`) and structured-output validation (`output_config.format` via `zodOutputFormat`), so the model's response is constrained to the exact schema in `JudgmentResponseSchema`.
4. Re-validates the model's output server-side (belt-and-suspenders — the client validates independently too, per `API_CONTRACT.md`).
5. Returns `{ verdict, reason, recommended_action, rewrite_options }` as JSON.

## What it deliberately does NOT do

- **No logging of request or response content.** `api/judge.ts` only ever logs an error *type* (e.g. `"judge_error: timeout"`), never the proposed message, pasted conversation, or model output.
- **No persistence.** This is a stateless function — no database, no file writes, nothing written anywhere between requests.
- **No authentication/rate-limiting beyond basic request-size validation.** This is a known, documented tradeoff for a Day 1/2 experiment — see "Known limitation: abuse mitigation" below before this app has real production traffic.
- **No CORS configuration.** The iOS client calls this directly via `URLSession`, not from a browser, so no `Access-Control-Allow-Origin` handling is needed. If a web client is ever added, CORS will need to be configured then.

## Deploying (Vercel — recommended)

This is written as a [Vercel](https://vercel.com) serverless function because it requires zero infrastructure setup beyond `vercel deploy` and gives you built-in HTTPS, environment variable management, and a generous free tier. Any Node-compatible serverless platform (Cloudflare Workers with adaptation, AWS Lambda via a thin adapter, Fly.io, etc.) would also work — the `api/judge.ts` handler itself has no Vercel-specific logic beyond the `VercelRequest`/`VercelResponse` types.

1. **Install the Vercel CLI** (`npm install -g vercel`) and run `vercel login` if you haven't already.
2. **From this `server/` directory**, run `npm install`.
3. **Get an Anthropic API key** from [console.anthropic.com](https://console.anthropic.com) if you don't have one.
4. **Deploy**: `vercel` (first time) or `vercel --prod` (production deploy). Follow the prompts to link/create a project.
5. **Set the API key as an encrypted environment variable** — do this in the Vercel dashboard (Project → Settings → Environment Variables), name `ANTHROPIC_API_KEY`, value = your key, scoped to Production (and Preview if you want preview deployments to work). **Never** put the real key in a committed file — `.env.example` is a template, not a real config.
6. **Redeploy** after setting the environment variable (`vercel --prod`) so the function picks it up.
7. **Note the deployed URL** (e.g. `https://should-i-text-him-<hash>.vercel.app`). The actual endpoint is `<that URL>/api/judge`.
8. **Update the iOS client** — `RemoteAIJudgmentProvider.defaultEndpoint` in `../ShouldITextHim/Engine/RemoteAIJudgmentProvider.swift` is currently a placeholder (`https://should-i-text-him.example.com/api/judge`). Replace it with your real deployed URL before shipping. This is tracked in `../FOUNDER_ACTION_REQUIRED.md`.

### Local development

```bash
cp .env.example .env   # then fill in your real key — .env is gitignored
npm install
npm run dev             # runs `vercel dev`, serves the function locally
```

Point a local build of the iOS app at `http://localhost:3000/api/judge` (or whatever port `vercel dev` reports) by passing a custom `endpoint` to `RemoteAIJudgmentProvider.init` for local testing.

## Known limitation: abuse mitigation

This endpoint has **no per-caller rate limiting or request authentication** beyond a basic payload-size cap. That's a deliberate, documented tradeoff, not an oversight: real distributed rate limiting requires an external store (Redis/Upstash, Vercel KV, etc.) that would be disproportionate infrastructure for a Day 1 experiment with no production traffic yet, and a naive in-memory counter in a serverless function gives false confidence — it resets on every cold start and doesn't work at all across concurrent instances. See `../SECURITY_REVIEW.md` for the full classification of this as an accepted risk with a documented follow-up path.

**Before this app has meaningful real-world traffic**, add one of:
- A KV-backed rate limiter (Vercel KV, Upstash Redis) keyed by IP and/or a lightweight per-app token.
- Apple's [DeviceCheck/App Attest](https://developer.apple.com/documentation/devicecheck) to cryptographically verify requests come from a genuine instance of this app, verified server-side against Apple's servers — the strongest option, but a meaningfully larger implementation than this endpoint currently has.
- Vercel's built-in Attack Challenge Mode / Firewall rules as a stopgap.

None of these are implemented yet. This is tracked in `../POST_LAUNCH.md`.

## Cost

`claude-opus-5` is used per Anthropic's current guidance (see the model table this was built against). Effort is set to `"low"` for this classification-style task to keep latency and cost down without switching to a smaller/cheaper model. Actual per-request cost depends on prompt length (bounded — see `JudgmentRequestSchema`'s length limits) and response length (bounded to ~400 chars reason + up to 3 short rewrite options). Monitor actual spend in the Anthropic Console once deployed; switching models (e.g. to a Sonnet or Haiku tier) is a one-line change in `api/judge.ts` if cost becomes a concern — that's a founder cost/quality tradeoff decision, not something this code should silently do for you.
