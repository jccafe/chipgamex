#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "[ERR] .env not found in $(pwd)"
  exit 1
fi

# 讀取現有設定
DB_USER="$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)"
DB_NAME="$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)"

if [[ -z "${DB_USER}" || -z "${DB_NAME}" ]]; then
  echo "[ERR] POSTGRES_USER or POSTGRES_DB is empty in .env"
  exit 1
fi

# 產生新密碼（可手動傳入）
# 用法:
#   ./rotate_db_password.sh                # 自動生成
#   ./rotate_db_password.sh 'MyNewPass!xx' # 指定密碼
if [[ $# -ge 1 ]]; then
  NEW_DB_PASS="$1"
else
  NEW_DB_PASS="ChipGX_$(date +%Y)_$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-24)!"
fi

echo "[INFO] Backing up .env ..."
cp .env ".env.bak_$(date +%F_%H%M%S)"

echo "[INFO] Updating .env POSTGRES_PASSWORD ..."
# 若有特殊字元，使用 awk 較穩
awk -v newpass="$NEW_DB_PASS" '
BEGIN{updated=0}
{
  if ($0 ~ /^POSTGRES_PASSWORD=/) { print "POSTGRES_PASSWORD=" newpass; updated=1; next }
  print
}
END{
  if(updated==0) print "POSTGRES_PASSWORD=" newpass
}
' .env > .env.tmp && mv .env.tmp .env

echo "[INFO] Applying password inside PostgreSQL ..."
docker compose exec -T db psql -U "$DB_USER" -d postgres -c "ALTER USER \"$DB_USER\" WITH PASSWORD '${NEW_DB_PASS}';"

echo "[INFO] Recreating api/web to reload env ..."
docker compose up -d --force-recreate api web

echo "[INFO] Health check ..."
sleep 2
curl -fsS http://localhost:8000/api/v1/health && echo

echo
echo "[DONE] DB password rotated successfully."
echo "[INFO] DB_USER=$DB_USER DB_NAME=$DB_NAME"
echo "[INFO] New password:"
echo "$NEW_DB_PASS"
echo
echo "[IMPORTANT] Please store this password in your password manager immediately."
