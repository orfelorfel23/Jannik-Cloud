#!/bin/bash
###############################################################################
# entrypoint.sh — Generates rclone.conf from .env, sets up cron, starts crond
###############################################################################
set -euo pipefail

# Timezone
export TZ="${TZ:-Europe/Berlin}"
cp "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" > /etc/timezone

# Ensure directories exist
mkdir -p /backup/rclone /backup/staging/db /backup/staging/meta /var/log

###############################################################################
# Generate rclone.conf from environment variable
###############################################################################
RCLONE_CONF="/backup/rclone/rclone.conf"

if [[ -n "${RCLONE_DRIVE_TOKEN:-}" && "${RCLONE_DRIVE_TOKEN}" != "PASTE_TOKEN_HERE" ]]; then
    cat > "${RCLONE_CONF}" <<EOF
[gdrive]
type = drive
scope = drive
token = ${RCLONE_DRIVE_TOKEN}
EOF
    chmod 600 "${RCLONE_CONF}"
    echo "[OK] rclone.conf generated from RCLONE_DRIVE_TOKEN."
else
    echo "[WARN] RCLONE_DRIVE_TOKEN not set or invalid."
    echo "[WARN] Backups will FAIL. Re-run generate-env.sh to configure."
fi

###############################################################################
# Set up cron
###############################################################################
CRON_SCHEDULE="${BACKUP_CRON:-0 3 * * *}"

# Export all env vars so cron job inherits them
env | grep -v '^_=' | grep -v '^HOME=' | grep -v '^HOSTNAME=' | \
    sed 's/=\(.*\)/="\1"/' > /app/env.sh

echo "${CRON_SCHEDULE} /bin/bash -c 'source /app/env.sh && /app/backup.sh >> /var/log/backup.log 2>&1'" \
    > /etc/crontabs/root

echo "==========================================="
echo "  Jannik-Cloud Backup Service"
echo "==========================================="
echo "  Schedule:  ${CRON_SCHEDULE}"
echo "  Remote:    ${GDRIVE_REMOTE:-gdrive}:${GDRIVE_PATH:-Jannik-Cloud-Backups}"
echo "  Retention: ${RETENTION_DAYS:-30} days"
echo "==========================================="

# Start cron in foreground
crond -f -l 2
