#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="minecraft"
DATA_DIR="data"
BACKUP_DIR="backups"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP_FILE="${BACKUP_DIR}/minecraft-data-${TIMESTAMP}.tar.gz"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found" >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "ERROR: tar command not found" >&2
  exit 1
fi

if ! docker compose ps --services --status running | grep -qx "${SERVICE_NAME}"; then
  echo "ERROR: ${SERVICE_NAME} service is not running" >&2
  exit 1
fi

if [[ ! -d "${DATA_DIR}" ]]; then
  echo "ERROR: ${DATA_DIR}/ does not exist" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

SAVE_DISABLED=0

restore_saving() {
  if [[ "${SAVE_DISABLED}" -eq 1 ]]; then
    echo "Re-enabling Minecraft world saving..."
    docker compose exec -T "${SERVICE_NAME}" rcon-cli save-on >/dev/null 2>&1 || true
  fi
}

trap restore_saving EXIT INT TERM

echo "Flushing world data to disk..."
docker compose exec -T "${SERVICE_NAME}" rcon-cli save-all flush

echo "Temporarily disabling automatic world saves..."
docker compose exec -T "${SERVICE_NAME}" rcon-cli save-off
SAVE_DISABLED=1

echo "Creating ${BACKUP_FILE} ..."
tar -czf "${BACKUP_FILE}" "${DATA_DIR}"

echo "Re-enabling automatic world saves..."
docker compose exec -T "${SERVICE_NAME}" rcon-cli save-on
SAVE_DISABLED=0

echo "Backup completed: ${BACKUP_FILE}"
