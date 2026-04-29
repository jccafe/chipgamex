#!/usr/bin/env bash
set -euo pipefail

# ===== Config (可依環境調整) =====
API_URL="${API_URL:-http://localhost:8000/api/v1/health}"
WEB_URL="${WEB_URL:-http://localhost:8080/}"
BACKUP_DIR="${BACKUP_DIR:-/home/jc/backups/chipgamex}"
MAX_BACKUP_AGE_MIN="${MAX_BACKUP_AGE_MIN:-1440}" # 24h

ok()   { echo -e "[OK]    $*"; }
warn() { echo -e "[WARN]  $*"; }
fail() { echo -e "[FAIL]  $*"; exit 1; }

echo "== ChipGameX Health Check =="
echo "Time: $(date '+%F %T')"
echo

# 1) compose services
echo "1) Docker Compose services"
if docker compose ps >/tmp/chipgamex_ps.txt 2>/dev/null; then
  cat /tmp/chipgamex_ps.txt
  # 檢查是否有 Exited/Dead
  if grep -Eiq 'exited|dead' /tmp/chipgamex_ps.txt; then
    fail "Some containers are not running."
  else
    ok "Compose services look running."
  fi
else
  fail "docker compose ps failed."
fi
echo

# 2) API health
echo "2) API health: ${API_URL}"
if curl -fsS --max-time 10 "${API_URL}" >/tmp/chipgamex_api_health.json; then
  head -c 300 /tmp/chipgamex_api_health.json; echo
  ok "API health reachable."
else
  fail "API health check failed."
fi
echo

# 3) Web health
echo "3) Web health: ${WEB_URL}"
if curl -fsS -I --max-time 10 "${WEB_URL}" | head -n 1 | grep -q "200"; then
  ok "Web reachable (HTTP 200)."
else
  fail "Web check failed (not HTTP 200)."
fi
echo

# 4) Backup freshness
echo "4) Backup freshness: ${BACKUP_DIR}"
if [ ! -d "${BACKUP_DIR}" ]; then
  warn "Backup dir not found: ${BACKUP_DIR}"
else
  # 找 24 小時內有異動的檔案
  if find "${BACKUP_DIR}" -type f -mmin -"${MAX_BACKUP_AGE_MIN}" | grep -q .; then
    latest="$(find "${BACKUP_DIR}" -type f -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
    ok "Recent backup exists. Latest: ${latest}"
  else
    warn "No backup file updated within ${MAX_BACKUP_AGE_MIN} minutes."
  fi
fi
echo

ok "Health check completed."
