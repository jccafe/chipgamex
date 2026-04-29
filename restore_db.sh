#!/usr/bin/env bash
set -euo pipefail

cd ~/chipgamex

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /full/path/to/backup.dump.gz"
  exit 1
fi

BACKUP_FILE="$1"
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "[ERR] backup file not found: $BACKUP_FILE"
  exit 1
fi

DB_USER="$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)"
DB_NAME="$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)"

echo "[WARN] This will RESTORE into database '$DB_NAME' and overwrite existing objects."
read -r -p "Type YES to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "[INFO] Aborted."
  exit 0
fi

TMP_FILE="/tmp/restore_$(date +%s).dump"
echo "[INFO] Decompressing backup..."
gunzip -c "$BACKUP_FILE" > "$TMP_FILE"

echo "[INFO] Restoring..."
cat "$TMP_FILE" | docker compose exec -T db pg_restore -U "$DB_USER" -d "$DB_NAME" --clean --if-exists --no-owner --no-privileges

rm -f "$TMP_FILE"

echo "[INFO] Restore done. Running health check..."
curl -fsS http://localhost:8000/api/v1/health && echo
echo "[DONE] Restore completed successfully."
