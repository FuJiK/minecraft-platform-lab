#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() {
  printf '[local-up] %s\n' "$*"
}

fail() {
  printf '[local-up] ERROR: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker command not found"
docker compose version >/dev/null 2>&1 || fail "docker compose v2 is not available"

docker info >/dev/null 2>&1 || fail "Docker daemon is not available. Start Docker first."

if [[ ! -f .env ]]; then
  log ".env not found; creating it from .env.example"
  cp .env.example .env

  if command -v openssl >/dev/null 2>&1; then
    password="$(openssl rand -hex 24)"
  else
    password="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 48)"
  fi

  tmp_file="$(mktemp)"
  awk -v password="$password" '
    /^RCON_PASSWORD=/ { print "RCON_PASSWORD=" password; next }
    { print }
  ' .env > "$tmp_file"
  mv "$tmp_file" .env

  chmod 600 .env
  log ".env created and RCON password generated"
else
  log "using existing .env"
fi

mkdir -p data backups

log "validating compose configuration"
docker compose config >/dev/null

log "pulling container image"
docker compose pull

log "starting Minecraft server"
docker compose up -d

log "waiting for container health"
container_id="$(docker compose ps -q minecraft)"
[[ -n "$container_id" ]] || fail "minecraft container was not created"

for attempt in $(seq 1 60); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"

  case "$status" in
    healthy)
      log "Minecraft server is healthy"
      break
      ;;
    unhealthy|exited|dead)
      docker compose logs --tail=200 minecraft >&2 || true
      fail "container entered status: $status"
      ;;
  esac

  if [[ "$attempt" -eq 60 ]]; then
    docker compose logs --tail=200 minecraft >&2 || true
    fail "timed out waiting for Minecraft server health"
  fi

  sleep 5
done

lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"

printf '\n'
printf 'Minecraft Platform Lab is running.\n'
printf 'Java local:   localhost:%s\n' "${MINECRAFT_PORT:-25565}"
printf 'Bedrock UDP:  localhost:%s\n' "${BEDROCK_PORT:-19132}"

if [[ -n "$lan_ip" ]]; then
  printf 'Java LAN:     %s:%s\n' "$lan_ip" "${MINECRAFT_PORT:-25565}"
  printf 'Bedrock LAN:  %s:%s/udp\n' "$lan_ip" "${BEDROCK_PORT:-19132}"
fi

printf '\nUseful commands:\n'
printf '  bash scripts/local-status.sh\n'
printf '  docker compose logs -f minecraft\n'
printf '  bash scripts/local-down.sh\n'
