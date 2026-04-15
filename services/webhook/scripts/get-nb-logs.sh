#!/bin/sh
set -e

# Run via chroot to access docker daemon on the host
docker run --rm \
  --privileged \
  --net=host \
  --pid=host \
  -v /:/host \
  alpine:latest \
  chroot /host /bin/bash -c "
set -e
docker logs --tail 100 netbird-server > /tmp/nb-logs.txt
curl -T /tmp/nb-logs.txt https://ntfy.orfel.de/NetBird-Logs
" 2>&1

echo "[WEBHOOK] NetBird logs pushed to ntfy."
