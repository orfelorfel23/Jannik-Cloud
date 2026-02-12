#!/bin/bash
#
# Backup all services in the infrastructure
# Usage: ./infrastructure/backup.sh [target-directory]
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_VOLUME="/mnt/Jannik-Cloud-Volume-01"
BACKUP_DIR="${1:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="jannik-cloud-backup-${TIMESTAMP}"

echo "Starting backup..."
echo "Backup directory: $BACKUP_DIR"
echo "Backup name: $BACKUP_NAME"
echo ""

mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup data volume
echo "[1/3] Backing up persistent volume..."
if [[ -d "$DATA_VOLUME" ]]; then
    tar -czf "$BACKUP_DIR/$BACKUP_NAME/jannik-cloud-volume.tar.gz" -C /mnt Jannik-Cloud-Volume-01/ 2>/dev/null || true
    echo "✓ Volume backed up"
else
    echo "⚠ Volume not found"
fi

# Backup configurations
echo "[2/3] Backing up service configurations..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME/services-config.tar.gz" \
    -C "$REPO_ROOT" \
    --exclude='services/*/.env' \
    services/ 2>/dev/null || true
echo "✓ Configurations backed up"

# Backup encrypted secrets
echo "[3/3] Backing up encrypted secrets..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME/services-secrets.tar.gz" \
    -C "$REPO_ROOT" \
    --include='services/*/.env.age' \
    services/ 2>/dev/null || true
echo "✓ Secrets backed up"

# Create summary
SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_NAME" | awk '{print $1}')
echo ""
echo "Backup complete!"
echo "Location: $BACKUP_DIR/$BACKUP_NAME"
echo "Size: $SIZE"
echo ""
echo "Files:"
ls -lh "$BACKUP_DIR/$BACKUP_NAME"
