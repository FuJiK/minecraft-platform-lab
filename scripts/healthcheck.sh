#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="minecraft"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found" >&2
  exit 1
fi

if ! docker compose ps --services --status running | grep -qx "${SERVICE_NAME}"; then
  echo "ERROR: ${SERVICE_NAME} service is not running" >&2
  docker compose ps
  exit 1
fi

CONTAINER_ID="$(docker compose ps -q "${SERVICE_NAME}")"

if [[ -z "${CONTAINER_ID}" ]]; then
  echo "ERROR: container id was not found" >&2
  exit 1
fi

HEALTH_STATUS="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "${CONTAINER_ID}")"

case "${HEALTH_STATUS}" in
  healthy)
    echo "OK: Minecraft server is healthy"
    ;;
  starting)
    echo "WAIT: Minecraft server healthcheck is still starting"
    exit 2
    ;;
  unhealthy)
    echo "ERROR: Minecraft server is unhealthy" >&2
    docker compose logs --tail=100 "${SERVICE_NAME}"
    exit 1
    ;;
  no-healthcheck)
    echo "ERROR: healthcheck is not configured" >&2
    exit 1
    ;;
  *)
    echo "ERROR: unknown health status: ${HEALTH_STATUS}" >&2
    exit 1
    ;;
esac
