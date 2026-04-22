#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_db_sql> <path_to_files_tar_gz>"
    echo "Example: $0 ~/baserow_backups/baserow_db_2026...sql ~/baserow_backups/baserow_files_2026...tar.gz"
    exit 1
fi

DB_BACKUP_FILE="$1"
FILES_BACKUP_FILE="$2"

echo "======================================"
echo " Baserow Restore Script "
echo "======================================"

if [ ! -f "${DB_BACKUP_FILE}" ]; then
    echo "Error: DB backup file not found: ${DB_BACKUP_FILE}"
    exit 1
fi

if [ ! -f "${FILES_BACKUP_FILE}" ]; then
    echo "Error: Files backup not found: ${FILES_BACKUP_FILE}"
    exit 1
fi

echo "WARNING: This will overwrite current Baserow data."
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# We must ensure Postgres is running, but let's just assume it is because 
# the user ran deploy_script.sh on the new server already.

# 1. Restore PostgreSQL Database
echo "[1/2] Dropping and Recreating 'baserow_db' to ensure clean import..."
# Terminate existing connections
docker exec postgres psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'baserow_db' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
docker exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS baserow_db;" >/dev/null 2>&1 || true
docker exec postgres psql -U postgres -c "CREATE DATABASE baserow_db OWNER baserow_user;" >/dev/null 2>&1 || true

echo "[1/2] Importing PostgreSQL database 'baserow_db'..."
cat "${DB_BACKUP_FILE}" | docker exec -i postgres psql -U postgres -d baserow_db
echo "      -> DB restored."

# 2. Restore Filesystem (Pictures/Uploads)
echo "[2/2] Restoring uploaded files and pictures..."
mkdir -p /mnt/Jannik-Cloud-Volume-01/baserow
# Clear existing files just in case
rm -rf /mnt/Jannik-Cloud-Volume-01/baserow/*
tar -xzf "${FILES_BACKUP_FILE}" -C /mnt/Jannik-Cloud-Volume-01/baserow
echo "      -> Files restored."

echo "======================================"
echo " Restore completed successfully!"
echo " Restarting Baserow..."
cd "$(dirname "$0")"
docker compose restart baserow || true
echo "======================================"
