#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat > "${SCRIPT_DIR}/syncthing.caddy" <<'EOF'
sync.orfel.de {
	reverse_proxy syncthing:8384
}
EOF

echo "Syncthing environment generated."
