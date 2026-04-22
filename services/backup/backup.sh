#!/bin/bash
###############################################################################
# backup.sh — Main backup script
#
# What it does:
#   1. pg_dumpall → compressed SQL dump (consistent database snapshot)
#   2. Save file permissions manifest (UID, GID, mode for every file)
#   3. rclone sync /mnt to Google Drive (mirrors all service data)
#   4. rclone copy SQL dumps + permissions manifest to Google Drive
#   5. Clean up old dumps beyond retention period
#   6. Notify via ntfy
###############################################################################
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
STAGING="/backup/staging"
DATA="/mnt/data"
RCLONE_CONF="/backup/rclone/rclone.conf"
RCLONE_REMOTE="${GDRIVE_REMOTE:-gdrive}"
RCLONE_PATH="${GDRIVE_PATH:-Jannik-Cloud-Backups}"
RETENTION="${RETENTION_DAYS:-30}"
NTFY="${NTFY_URL:-}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

notify() {
    local title="$1" message="$2"
    local priority="${3:-default}" tags="${4:-}"
    if [[ -n "${NTFY}" ]]; then
        curl -s -o /dev/null --retry 2 --max-time 10 \
            -H "Title: ${title}" \
            -H "Priority: ${priority}" \
            -H "Tags: ${tags}" \
            -d "${message}" \
            "${NTFY}" 2>/dev/null || true
    fi
}

# Pre-flight check
if [[ ! -f "${RCLONE_CONF}" ]]; then
    log "ERROR: rclone.conf not found. Run: docker exec -it backup rclone config --config ${RCLONE_CONF}"
    notify "Backup FEHLGESCHLAGEN" "rclone nicht konfiguriert! Kein Backup möglich." "urgent" "x,warning"
    exit 1
fi

log "==========================================="
log "  Backup started"
log "==========================================="
BACKUP_START=$(date +%s)
notify "Backup gestartet" "Tägliches Backup um $(date '+%H:%M') gestartet..." "default" "floppy_disk"

mkdir -p "${STAGING}/db" "${STAGING}/meta"

###############################################################################
# 1. PostgreSQL — Full logical dump (all databases + roles)
###############################################################################
log "--- Step 1/5: PostgreSQL dump ---"
PG_DUMP_FILE="${STAGING}/db/pg_dumpall_${TIMESTAMP}.sql"
export PGPASSWORD="${POSTGRES_PASSWORD}"

if pg_dumpall -h "${POSTGRES_HOST:-postgres}" -U "${POSTGRES_USER:-postgres}" \
    > "${PG_DUMP_FILE}" 2>/dev/null; then
    gzip -f "${PG_DUMP_FILE}"
    DUMP_SIZE=$(du -sh "${PG_DUMP_FILE}.gz" | cut -f1)
    log "PostgreSQL dump complete: ${DUMP_SIZE}"
else
    log "WARNING: PostgreSQL dump failed. Continuing with file backup..."
    notify "Backup: PG-Dump fehlgeschlagen" \
        "PostgreSQL-Dump konnte nicht erstellt werden. Datei-Backup läuft weiter." \
        "high" "warning"
    rm -f "${PG_DUMP_FILE}"
fi

###############################################################################
# 2. File permissions manifest (numeric UID/GID + mode)
###############################################################################
log "--- Step 2/5: Saving permissions manifest ---"
PERM_FILE="${STAGING}/meta/permissions_${TIMESTAMP}.txt"

# Save: mode uid gid /path — using numeric IDs for exact restoration
find "${DATA}" -not -path "${DATA}/backup/*" \
    -exec stat -c '%a %u %g %n' {} \; \
    > "${PERM_FILE}" 2>/dev/null || true
gzip -f "${PERM_FILE}"
log "Permissions manifest saved."

###############################################################################
# 3. Sync service data to Google Drive (mirror)
###############################################################################
log "--- Step 3/5: Syncing service data to Google Drive ---"
rclone sync "${DATA}" "${RCLONE_REMOTE}:${RCLONE_PATH}/data" \
    --config "${RCLONE_CONF}" \
    --transfers 4 \
    --checkers 8 \
    --exclude "backup/**" \
    --log-level NOTICE \
    --stats 30s

log "Service data sync complete."

###############################################################################
# 4. Upload DB dumps + permission manifests (copy, not sync — keep history)
###############################################################################
log "--- Step 4/5: Uploading dumps and manifests ---"
rclone copy "${STAGING}" "${RCLONE_REMOTE}:${RCLONE_PATH}/meta" \
    --config "${RCLONE_CONF}" \
    --log-level NOTICE

log "Dumps and manifests uploaded."

###############################################################################
# 5. Clean up old files beyond retention
###############################################################################
log "--- Step 5/5: Cleaning up old backups ---"

# Local cleanup
find "${STAGING}/db" -name "*.sql.gz" -mtime "+${RETENTION}" -delete 2>/dev/null || true
find "${STAGING}/meta" -name "*.txt.gz" -mtime "+${RETENTION}" -delete 2>/dev/null || true

# Remote cleanup — delete dump/manifest files older than retention
rclone delete "${RCLONE_REMOTE}:${RCLONE_PATH}/meta/db" \
    --config "${RCLONE_CONF}" \
    --min-age "${RETENTION}d" 2>/dev/null || true
rclone delete "${RCLONE_REMOTE}:${RCLONE_PATH}/meta/meta" \
    --config "${RCLONE_CONF}" \
    --min-age "${RETENTION}d" 2>/dev/null || true

log "Cleanup complete."

###############################################################################
# Done
###############################################################################
ELAPSED=$(( $(date +%s) - BACKUP_START ))
log "==========================================="
log "  Backup complete in $((ELAPSED / 60))m $((ELAPSED % 60))s"
log "==========================================="

notify "Backup abgeschlossen ✅" \
    "Backup erfolgreich in $((ELAPSED / 60))m $((ELAPSED % 60))s. Nächstes Backup morgen um 03:00." \
    "default" "white_check_mark"
