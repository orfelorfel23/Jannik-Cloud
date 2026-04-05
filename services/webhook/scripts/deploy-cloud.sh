#!/bin/sh
set -e

NTFY_URL="https://ntfy.orfel.de/Jannik-Cloud-Deploy-Trigger"
LOCK_FILE="/tmp/jannik-cloud-deploy.lock"
LOG_FILE="/var/log/jannik-cloud-deploy.log"

# All work happens on the host via chroot
docker run --rm \
  --privileged \
  --net=host \
  --pid=host \
  -v /:/host \
  alpine:latest \
  chroot /host /bin/bash -c "
set -e

NTFY_URL='${NTFY_URL}'
LOCK_FILE='${LOCK_FILE}'
LOG_FILE='${LOG_FILE}'
export TZ='Europe/Berlin'
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# --- Notify: Push detected ---
curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
  -H 'Title: GitHub Push erkannt' \\
  -H 'Tags: rocket' \\
  -d \"Neuer Push zu Jannik-Cloud um \${TIMESTAMP}. Deployment wird vorbereitet...\" \\
  \"\${NTFY_URL}\" 2>/dev/null || true

echo \"[\${TIMESTAMP}] GitHub push detected\" >> \"\${LOG_FILE}\"

# --- Lock check: prevent concurrent deploys ---
if [ -f \"\${LOCK_FILE}\" ]; then
  LOCK_PID=\$(cat \"\${LOCK_FILE}\" 2>/dev/null || echo 'unknown')
  curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
    -H 'Title: Deployment übersprungen' \\
    -H 'Tags: warning' \\
    -d \"Ein Deployment läuft bereits (PID: \${LOCK_PID}). Dieser Trigger wird übersprungen.\" \\
    \"\${NTFY_URL}\" 2>/dev/null || true
  echo \"[\${TIMESTAMP}] Skipped — already running (PID: \${LOCK_PID})\" >> \"\${LOG_FILE}\"
  exit 0
fi

# --- Create lock ---
echo \$\$ > \"\${LOCK_FILE}\"
trap 'rm -f \"\${LOCK_FILE}\"' EXIT

# --- Pull and deploy (deploy_script.sh handles its own ntfy notifications) ---
cd /opt/Jannik-Cloud
git fetch origin >> \"\${LOG_FILE}\" 2>&1
git reset --hard origin/main >> \"\${LOG_FILE}\" 2>&1
bash deploy_script.sh 2>&1 | tee -a \"\${LOG_FILE}\"

echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] Webhook deploy finished\" >> \"\${LOG_FILE}\"
" 2>&1

echo "[WEBHOOK] Full deploy complete."
