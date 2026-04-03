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
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
  -H 'Title: Linus Rebuild startet' \\
  -H 'Priority: default' \\
  -H 'Tags: hammer' \\
  -d "Push für Linus-Website um \${TIMESTAMP} erkannt. Container wird neu gebaut..." \\
  "\${NTFY_URL}"

cd /opt/Jannik-Cloud/services/linus
docker compose build --no-cache 2>&1 || {
  curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
    -H 'Title: Linus Rebuild FEHLGESCHLAGEN' \\
    -H 'Priority: urgent' \\
    -H 'Tags: x' \\
    -d 'Linus Container Build ist fehlgeschlagen. Prüfe die Server-Logs.' \\
    "\${NTFY_URL}"
  exit 1
}

docker compose up -d --remove-orphans --force-recreate 2>&1

curl -s -o /dev/null --retry 3 --retry-delay 2 --max-time 10 \\
  -H 'Title: Linus Rebuild abgeschlossen' \\
  -H 'Priority: default' \\
  -H 'Tags: white_check_mark' \\
  -d 'Linus Website-Container wurde erfolgreich neu gebaut und gestartet.' \\
  "\${NTFY_URL}"
" 2>&1

echo "[WEBHOOK] Linus rebuild complete."
