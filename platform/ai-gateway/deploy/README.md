# theAIgincy production AI infrastructure

This directory deploys the shared AI backend used by every AI-enabled micro-app.

## Production topology

Internet -> HTTPS (Caddy) -> theAIgincy AI Gateway -> private Ollama network -> local model

Only TCP 80/443 are published by the stack. Ollama is never published to the host or internet. Its Docker network is marked `internal: true`.

## Host requirements

Use an always-on Linux machine with a public IP, Docker Engine + Docker Compose v2, and enough RAM/storage for the selected model. For qwen3:4b, budget at least 8 GB RAM; 16 GB gives materially more operating headroom. CPU-only inference works but can be slower. GPU acceleration can be added later without changing the mobile apps.

## DNS (one time)

Create an A record at the DNS provider for:

`api.theaigincy.com -> <production server public IPv4>`

If the host also has IPv6 and is reachable on it, an AAAA record may be added. Do not create an AAAA record that points to an unreachable IPv6 address because ACME validation can fail.

Ports 80 and 443 must reach this machine. Caddy uses them to obtain and renew TLS certificates automatically.

## First deployment

From the repository on the production host:

```sh
cd platform/ai-gateway/deploy
cp .env.production.example .env.production
```

Edit `.env.production` and set at minimum:

- `API_DOMAIN=api.theaigincy.com`
- `ACME_EMAIL=<real certificate/admin email>`
- `LOCAL_LLM_MODEL=qwen3:4b` (or another benchmark-approved model)

Then run:

```sh
chmod +x deploy.sh
./deploy.sh
```

The script validates Compose, builds the gateway, starts Ollama and Caddy, pulls the configured model, then leaves all long-running services under Docker restart supervision.

## Verification

```sh
docker compose --env-file .env.production -f docker-compose.prod.yml ps
curl -fsS https://api.theaigincy.com/healthz
```

Expected health response:

```json
{"status":"ok"}
```

Then test the first application route with a non-sensitive fixture:

```sh
curl -sS https://api.theaigincy.com/v1/apps/should-i-text-him/judge \
  -H 'content-type: application/json' \
  --data '{"proposedMessage":"Want to grab coffee this weekend?","goal":"makePlans","context":{"quick":{"whoTextedLast":"him","timeSinceLastMessage":"today","didHeRespond":"yes","additionalNotes":"We have been chatting normally."}}}'
```

## Updating the gateway

Pull the approved repository revision on the host and run `./deploy.sh` again. Models remain in the persistent `ollama-data` volume and TLS state remains in the Caddy volumes.

## Backups

The gateway itself is stateless. The model volume can be recreated by pulling the configured model again. Caddy certificates can also be recreated automatically. There is no application database in this stack today.

## Security boundaries

- Ollama has no public port and sits only on an internal Docker network.
- The gateway is the only process allowed to talk to inference and the public edge.
- Caddy terminates TLS and forwards one trusted proxy hop; the gateway does not use unrestricted proxy trust.
- Request bodies/model prompts must not be logged. Caddy access logs contain request metadata but not request bodies.
- The gateway applies IP rate limiting. Do not treat a static API key embedded in an iOS binary as a secret; add Apple App Attest/device attestation later if abuse economics justify it.
- Keep `.env.production` off GitHub. It is gitignored.

## Operations

Useful commands:

```sh
# Status
docker compose --env-file .env.production -f docker-compose.prod.yml ps

# Gateway logs
docker compose --env-file .env.production -f docker-compose.prod.yml logs --tail=200 gateway

# Edge/TLS logs
docker compose --env-file .env.production -f docker-compose.prod.yml logs --tail=200 caddy

# Ollama logs
docker compose --env-file .env.production -f docker-compose.prod.yml logs --tail=200 ollama

# Restart
docker compose --env-file .env.production -f docker-compose.prod.yml restart

# Stop without deleting persistent volumes
docker compose --env-file .env.production -f docker-compose.prod.yml down
```

Never use `docker compose down -v` in production unless intentionally deleting the model and Caddy persistent volumes.
