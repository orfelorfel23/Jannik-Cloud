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

curl -s -o /dev/null \\
  -H 'Title: Linus Rebuild Starting' \\
  -H 'Priority: default' \\
  -H 'Tags: hammer' \\
  -d \"Linus website push detected at \${TIMESTAMP}. Rebuilding container...\" \\
  \"\${NTFY_URL}\"

cd /opt/Jannik-Cloud/services/linus
docker compose build --no-cache 2>&1 || {
  curl -s -o /dev/null \\
    -H 'Title: Linus Rebuild FAILED' \\
    -H 'Priority: urgent' \\
    -H 'Tags: x' \\
    -d 'Linus container build failed. Check server logs.' \\
    \"\${NTFY_URL}\"
  exit 1
}

docker compose up -d --remove-orphans --force-recreate 2>&1

curl -s -o /dev/null \\
  -H 'Title: Linus Rebuild Complete' \\
  -H 'Priority: default' \\
  -H 'Tags: white_check_mark' \\
  -d 'Linus website container has been rebuilt and restarted successfully.' \\
  \"\${NTFY_URL}\"
" 2>&1

echo "[WEBHOOK] Linus rebuild complete."
