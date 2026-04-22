# Backup — Google Drive via rclone

Automated daily backup of all Jannik-Cloud data to Google Drive.

## What Gets Backed Up

| Component | Method | Preserves |
|---|---|---|
| PostgreSQL (all databases + roles) | `pg_dumpall` → compressed SQL | Full logical dump, restorable on any PG version |
| All service files on `/mnt` | `rclone sync` → Google Drive | Files, directory structure |
| File permissions (UID/GID/mode) | Permission manifest `.txt.gz` | Exact ownership for restoration |

## First-Time Setup

### 1. Authorize Google Drive (on your local PC)

```bash
# Install rclone locally if needed:
#   Windows:  winget install Rclone.Rclone
#   Mac:      brew install rclone
#   Linux:    curl https://rclone.org/install.sh | sudo bash

rclone authorize "drive"
```

A browser opens for Google login. After authorizing, rclone prints a token like:
```
{"access_token":"ya29.a0A...","token_type":"Bearer","refresh_token":"1//0e...","expiry":"..."}
```
**Copy this entire JSON.**

### 2. Generate the environment file

```bash
cd /opt/Jannik-Cloud/services/backup
bash generate-env.sh
```

This prompts for:
- PostgreSQL root password (auto-read from `postgres/.env` if available)
- The rclone token you just copied

Everything is saved to `.env` and encrypted to `.env.age` — same as every other service.

### 3. Deploy

```bash
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

The entrypoint automatically generates `rclone.conf` from the token in `.env`. No manual `docker exec` needed.

### 4. Verify

```bash
# Run a manual backup to test
docker exec -it backup /app/backup.sh

# Check logs
docker exec -it backup cat /var/log/backup.log
```

## Schedule

Default: **daily at 03:00** (after the 02:31 deploy cron job).

```yaml
BACKUP_CRON: "0 3 * * *"     # Daily at 03:00 (default)
BACKUP_CRON: "0 */6 * * *"   # Every 6 hours
BACKUP_CRON: "0 3 * * 0"     # Weekly on Sunday at 03:00
```

## Manual Backup

```bash
docker exec -it backup /app/backup.sh
```

## Google Drive Structure

```
Jannik-Cloud-Backups/
├── data/                          ← Mirror of /mnt/Jannik-Cloud-Volume-01
│   ├── postgres/
│   ├── gitea/
│   ├── nextcloud/
│   ├── vaultwarden/
│   └── ...
│
└── meta/                          ← Point-in-time recovery snapshots
    ├── db/
    │   ├── pg_dumpall_20260422_030000.sql.gz
    │   └── ...                    ← 30 days of daily dumps
    └── meta/
        ├── permissions_20260422_030000.txt.gz
        └── ...                    ← 30 days of permission snapshots
```

---

## 🔥 FULL RESTORE PROCEDURE

### Scenario: Building a new server from scratch

**You need:**
- Fresh Ubuntu 24 LTS server with `/mnt` volume mounted
- Your AGE private key
- rclone installed (temporary, just for the restore)

### Step 1: Install rclone on the fresh server

```bash
curl https://rclone.org/install.sh | sudo bash
```

### Step 2: Authorize rclone

```bash
# On your LOCAL PC (with browser):
rclone authorize "drive"
# Copy the token JSON

# On the server — create a temporary config:
mkdir -p /tmp/rclone
cat > /tmp/rclone/rclone.conf <<EOF
[gdrive]
type = drive
scope = drive
token = PASTE_YOUR_TOKEN_HERE
EOF
```

### Step 3: Restore all data from Google Drive

```bash
sudo mkdir -p /mnt/Jannik-Cloud-Volume-01

# Download all service data
sudo rclone sync gdrive:Jannik-Cloud-Backups/data /mnt/Jannik-Cloud-Volume-01 \
    --config /tmp/rclone/rclone.conf \
    --transfers 8 \
    --progress

# Download dumps and permission manifests
sudo rclone copy gdrive:Jannik-Cloud-Backups/meta /mnt/Jannik-Cloud-Volume-01/backup/staging \
    --config /tmp/rclone/rclone.conf \
    --progress
```

### Step 4: Restore file permissions

```bash
# Find the latest manifest
LATEST_PERM=$(ls -t /mnt/Jannik-Cloud-Volume-01/backup/staging/meta/permissions_*.txt.gz | head -1)
gunzip -k "${LATEST_PERM}"
PERM_FILE="${LATEST_PERM%.gz}"

# Restore UID/GID/mode (container paths → host paths)
while IFS=' ' read -r mode uid gid filepath; do
    hostpath="${filepath/\/mnt\/data/\/mnt\/Jannik-Cloud-Volume-01}"
    if [[ -e "${hostpath}" ]]; then
        chmod "${mode}" "${hostpath}" 2>/dev/null || true
        chown "${uid}:${gid}" "${hostpath}" 2>/dev/null || true
    fi
done < "${PERM_FILE}"

echo "Permissions restored."
```

### Step 5: Deploy

```bash
git clone https://github.com/orfelorfel23/Jannik-Cloud.git /opt/Jannik-Cloud
sudo bash /opt/Jannik-Cloud/deploy_script.sh
# Enter your AGE private key when prompted
```

### Step 6 (if needed): Restore PostgreSQL from dump

Only needed if PostgreSQL fails to start (e.g., major version change):

```bash
# Find the latest dump
LATEST_DUMP=$(ls -t /mnt/Jannik-Cloud-Volume-01/backup/staging/db/pg_dumpall_*.sql.gz | head -1)

# Wipe old PG data and let a fresh container initialize
sudo rm -rf /mnt/Jannik-Cloud-Volume-01/postgres/*
cd /opt/Jannik-Cloud/services/postgres
docker compose up -d
sleep 10

# Restore
gunzip -c "${LATEST_DUMP}" | docker exec -i postgres psql -U postgres

# Redeploy everything
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

### Step 7: Verify

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Step 8: Clean up

```bash
rm -rf /tmp/rclone
```

---

## Retention

| What | Policy |
|---|---|
| Service data (Google Drive) | Always latest (rclone sync mirror) |
| PostgreSQL dumps | 30 days (configurable via `RETENTION_DAYS`) |
| Permission manifests | 30 days |

## Notifications

Pushed to `ntfy.orfel.de/Jannik-Cloud-Deploy-Trigger`:
- 💾 Backup started
- ✅ Backup completed (with duration)
- ❌ Backup failed (token missing, PG dump error, etc.)
