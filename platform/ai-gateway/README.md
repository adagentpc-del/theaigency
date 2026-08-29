# theAIgincy AI Gateway

One shared, self-hosted AI API for every AI-enabled app in this repository.

## Architecture

iOS apps -> `https://api.theaigincy.com` -> this gateway -> private Ollama/llama.cpp-compatible inference server.

Apps never call Ollama, llama.cpp, OpenAI, Anthropic, or any other model provider directly. The gateway owns app/task registration, prompt routing, output schemas, model selection, rate limiting, and inference-server credentials.

## Current app registry

- `should-i-text-him` / `judge`

Modern endpoint:

`POST /v1/apps/should-i-text-him/judge`

Backward-compatible endpoint during migration:

`POST /api/judge`

## Add a future app

1. Create `src/apps/<app-id>/`.
2. Define its Zod request/response schemas and JSON Schema for constrained model output.
3. Define system/user prompt builders.
4. Export a `GatewayAppDefinition` with a unique `id` + `task`.
5. Add it to `src/apps/registry.ts`.
6. Add a smoke-test case before merging.

No new server, public hostname, inference deployment, or hosted-AI key is required for each app.

## Model routing

`LOCAL_LLM_MODEL` is the default model for all apps. An app may override it with its own environment variable. `Should I Text Him` currently supports `SHOULD_I_TEXT_HIM_MODEL`.

This lets the factory move an app from `qwen3:4b` to `qwen3:8b` without shipping a new iOS binary.

## Development

```bash
npm install
npm run verify
LOCAL_LLM_BASE_URL=http://127.0.0.1:11434/v1 LOCAL_LLM_MODEL=qwen3:4b npm start
```

The inference server must expose an OpenAI-compatible `/v1/chat/completions` endpoint.

## Production rules

- Do not expose raw Ollama/llama.cpp publicly.
- Put HTTPS/reverse proxy in front of this gateway.
- Keep the model server on a private network/VPN/container network.
- Never log user prompt/body content.
- Set `TRUST_PROXY_HOPS` to the exact number of trusted proxy hops.
- The current in-memory IP limiter is suitable for a single gateway process. Before horizontal scaling, replace it with a shared limiter.
- A static API secret embedded in an iOS app is not real authentication. When abuse warrants stronger attestation, add Apple App Attest/DeviceCheck at this gateway layer once, rather than separately in every app.

## Shared client contract

Every AI app should treat the gateway base URL as infrastructure configuration and supply its app/task identity through the path:

`POST /v1/apps/{app-id}/{task}`

That is the permanent micro-app-factory convention.
