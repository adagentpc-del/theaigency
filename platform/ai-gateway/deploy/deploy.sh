#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed on this host." >&2
  exit 1
fi

if [ ! -f .env.production ]; then
  echo "Missing deploy/.env.production. Copy .env.production.example and fill API_DOMAIN + ACME_EMAIL." >&2
  exit 1
fi

docker compose --env-file .env.production -f docker-compose.prod.yml config >/dev/null
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build ollama gateway caddy
docker compose --env-file .env.production -f docker-compose.prod.yml run --rm model-init
docker compose --env-file .env.production -f docker-compose.prod.yml up -d gateway caddy

echo "Production AI stack deployed."
echo "Check: docker compose --env-file .env.production -f docker-compose.prod.yml ps"
