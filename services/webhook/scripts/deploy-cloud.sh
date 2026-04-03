#!/bin/sh
set -e
echo "[WEBHOOK] Triggering Jannik-Cloud full deploy..."
# The webhook container can't run the deploy script directly (it runs inside a container).
# Instead, use the Docker socket to run the deploy script on the HOST via a privileged container.
docker run --rm \
  --privileged \
  --net=host \
  --pid=host \
  -v /:/host \
  alpine:latest \
  chroot /host /bin/bash -c "cd /opt/Jannik-Cloud && git pull && bash deploy_script.sh" \
  2>&1
echo "[WEBHOOK] Full deploy complete."
