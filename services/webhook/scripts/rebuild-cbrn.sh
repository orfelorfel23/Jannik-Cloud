#!/bin/sh
set -e

NTFY_URL="https://ntfy.orfel.de/Jannik-Cloud-Deploy-Trigger"

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
export TZ='Europe/Berlin'
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
  -H 'Title: Content-Vault (CBRN) Rebuild startet' \\
  -H 'Priority: default' \\
  -H 'Tags: hammer' \\
  -d \"Push für Content-Vault um \${TIMESTAMP} erkannt. Container wird neu gebaut...\" \\
  \"\${NTFY_URL}\"

cd /opt/Jannik-Cloud/services/cbrn
docker compose build --no-cache 2>&1 || {
  curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
    -H 'Title: CBRN Rebuild FEHLGESCHLAGEN' \\
    -H 'Priority: urgent' \\
    -H 'Tags: x' \\
    -d 'CBRN Container Build ist fehlgeschlagen. Prüfe die Server-Logs.' \\
    \"\${NTFY_URL}\"
  exit 1
}

# Auto-Setup PostgreSQL mapping
DB_PASS=\$(grep POSTGRES_DB_PASSWORD .env | cut -d= -f2 | tr -d '[:space:]')
docker exec postgres psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = 'content_vault'" | grep -q 1 || docker exec postgres psql -U postgres -c "CREATE ROLE content_vault WITH LOGIN PASSWORD '\${DB_PASS}';"
docker exec postgres psql -U postgres -c "ALTER ROLE content_vault WITH PASSWORD '\${DB_PASS}';"
docker exec postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'content_vault'" | grep -q 1 || docker exec postgres psql -U postgres -c "CREATE DATABASE content_vault OWNER content_vault;"
docker exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE content_vault TO content_vault;"

docker compose up -d --remove-orphans --force-recreate 2>&1

curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
  -H 'Title: CBRN Rebuild abgeschlossen' \\
  -H 'Priority: default' \\
  -H 'Tags: white_check_mark' \\
  -d 'CBRN Service wurde erfolgreich neu gebaut und gestartet.' \\
  \"\${NTFY_URL}\"
" 2>&1

echo "[WEBHOOK] CBRN rebuild complete."
