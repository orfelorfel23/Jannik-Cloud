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
curl -s -o /dev/null \\
  -H 'Title: New Push Detected' \\
  -H 'Priority: default' \\
  -H 'Tags: rocket' \\
  -d \"A new GitHub push was detected at \${TIMESTAMP}. Checking deployment status...\" \\
  \"\${NTFY_URL}\"

echo \"[\${TIMESTAMP}] Push detected\" >> \"\${LOG_FILE}\"

# --- Lock check: prevent concurrent deploys ---
if [ -f \"\${LOCK_FILE}\" ]; then
  LOCK_PID=\$(cat \"\${LOCK_FILE}\" 2>/dev/null || echo 'unknown')
  curl -s -o /dev/null \\
    -H 'Title: Deploy Skipped' \\
    -H 'Priority: low' \\
    -H 'Tags: warning' \\
    -d \"A deployment is already running (PID: \${LOCK_PID}). This push will be handled by the next scheduled deploy.\" \\
    \"\${NTFY_URL}\"
  echo \"[\${TIMESTAMP}] Skipped — deploy already running (PID: \${LOCK_PID})\" >> \"\${LOG_FILE}\"
  exit 0
fi

# --- Create lock ---
echo \$\$ > \"\${LOCK_FILE}\"
trap 'rm -f \"\${LOCK_FILE}\"' EXIT

# --- Notify: Deploy starting ---
curl -s -o /dev/null \\
  -H 'Title: Deployment Starting' \\
  -H 'Priority: default' \\
  -H 'Tags: gear' \\
  -d \"Deploy script is now running. This may take a few minutes...\" \\
  \"\${NTFY_URL}\"

echo \"[\${TIMESTAMP}] Deploy started\" >> \"\${LOG_FILE}\"
START_TIME=\$(date +%s)

# --- Run deploy ---
cd /opt/Jannik-Cloud
git pull >> \"\${LOG_FILE}\" 2>&1
DEPLOY_OUTPUT=\$(bash deploy_script.sh 2>&1) || {
  END_TIME=\$(date +%s)
  DURATION=\$(( END_TIME - START_TIME ))
  MINUTES=\$(( DURATION / 60 ))
  SECONDS=\$(( DURATION % 60 ))

  curl -s -o /dev/null \\
    -H 'Title: Deployment FAILED' \\
    -H 'Priority: urgent' \\
    -H 'Tags: x,rotating_light' \\
    -d \"Deploy script failed after \${MINUTES}m \${SECONDS}s. Check server logs for details.\" \\
    \"\${NTFY_URL}\"

  echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] Deploy FAILED after \${MINUTES}m \${SECONDS}s\" >> \"\${LOG_FILE}\"
  exit 1
}

END_TIME=\$(date +%s)
DURATION=\$(( END_TIME - START_TIME ))
MINUTES=\$(( DURATION / 60 ))
SECONDS_LEFT=\$(( DURATION % 60 ))

# Count active services (no sensitive data)
SERVICES_COUNT=\$(echo \"\${DEPLOY_OUTPUT}\" | grep -c '  Starting ' || echo '?')

# --- Notify: Deploy complete ---
curl -s -o /dev/null \\
  -H 'Title: Deployment Complete' \\
  -H 'Priority: default' \\
  -H 'Tags: white_check_mark,tada' \\
  -d \"Deploy finished successfully in \${MINUTES}m \${SECONDS_LEFT}s. Services started: \${SERVICES_COUNT}.\" \\
  \"\${NTFY_URL}\"

echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] Deploy complete (\${MINUTES}m \${SECONDS_LEFT}s, \${SERVICES_COUNT} services)\" >> \"\${LOG_FILE}\"
" 2>&1

echo "[WEBHOOK] Full deploy complete."
