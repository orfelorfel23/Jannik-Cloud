#!/bin/sh
set -e
echo "[WEBHOOK] Triggering Jannik-Cloud full deploy..."
cd /opt/Jannik-Cloud
bash deploy_script.sh
echo "[WEBHOOK] Full deploy complete."
