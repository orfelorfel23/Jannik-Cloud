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
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

# --- Notify: Push detected ---
curl -s -o /dev/null --max-time 5 \\
  -H 'Title: GitHub Push Detected' \\
  -H 'Priority: default' \\
  -H 'Tags: rocket' \\
  -d \"New push to Jannik-Cloud at \${TIMESTAMP}. Preparing deployment...\" \\
  \"\${NTFY_URL}\" 2>/dev/null || true

echo \"[\${TIMESTAMP}] GitHub push detected\" >> \"\${LOG_FILE}\"

# --- Lock check: prevent concurrent deploys ---
if [ -f \"\${LOCK_FILE}\" ]; then
  LOCK_PID=\$(cat \"\${LOCK_FILE}\" 2>/dev/null || echo 'unknown')
  curl -s -o /dev/null --max-time 5 \\
    -H 'Title: Deploy Skipped' \\
    -H 'Priority: low' \\
    -H 'Tags: warning' \\
    -d \"A deployment is already running (PID: \${LOCK_PID}). Skipping this trigger.\" \\
    \"\${NTFY_URL}\" 2>/dev/null || true
  echo \"[\${TIMESTAMP}] Skipped — already running (PID: \${LOCK_PID})\" >> \"\${LOG_FILE}\"
  exit 0
fi

# --- Create lock ---
echo \$\$ > \"\${LOCK_FILE}\"
trap 'rm -f \"\${LOCK_FILE}\"' EXIT

# --- Pull and deploy (deploy_script.sh handles its own ntfy notifications) ---
cd /opt/Jannik-Cloud
git pull >> \"\${LOG_FILE}\" 2>&1
bash deploy_script.sh 2>&1 | tee -a \"\${LOG_FILE}\"

echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] Webhook deploy finished\" >> \"\${LOG_FILE}\"
" 2>&1

echo "[WEBHOOK] Full deploy complete."
