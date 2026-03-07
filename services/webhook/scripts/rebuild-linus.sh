#!/bin/sh
set -e
echo "[WEBHOOK] Rebuilding linus container..."
cd /opt/Jannik-Cloud/services/linus
docker compose build --no-cache
docker compose up -d --remove-orphans --force-recreate
echo "[WEBHOOK] Linus rebuild complete."
