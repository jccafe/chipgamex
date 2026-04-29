#!/usr/bin/env bash
set -euo pipefail

cd ~/chipgamex

BACKUP_DIR="$HOME/backups/chipgamex"
mkdir -p "$BACKUP_DIR"

DB_USER="$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)"
DB_NAME="$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)"

TS="$(date +%F_%H%M%S)"
OUT_FILE="$BACKUP_DIR/${DB_NAME}_${TS}.dump.gz"

echo "[INFO] backup -> $OUT_FILE"
docker compose exec -T db pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc | gzip > "$OUT_FILE"

echo "[INFO] done"
ls -lh "$OUT_FILE"

# 保留 14 天
find "$BACKUP_DIR" -type f -name "*.dump.gz" -mtime +14 -delete
