#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[1/5] docker compose pull (if any prebuilt image)"
docker compose pull || true

echo "[2/5] build images"
docker compose build --pull

echo "[3/5] start services"
docker compose up -d

echo "[4/5] status"
docker compose ps

echo "[5/5] health check"
sleep 3
curl -fsS http://localhost:8000/api/v1/health && echo
