#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

printf '== docker compose ps ==\n'
docker compose ps

printf '\n== recent minecraft logs ==\n'
docker compose logs --tail=80 minecraft || true

printf '\n== ports ==\n'
if command -v ss >/dev/null 2>&1; then
  ss -lntup | grep -E '(:25565|:19132)' || true
else
  printf 'ss command not available\n'
fi
