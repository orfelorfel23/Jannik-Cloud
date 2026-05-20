#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

cat > "${SCRIPT_DIR}/.env" <<EOF
# Navidrome Environment Configuration
# Navidrome creates its own admin user on first web login. No DB credentials needed.
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/navidrome.caddy" <<'EOF'
songs.orfel.de, song.orfel.de, suno.orfel.de, music.orfel.de, musik.orfel.de {
	reverse_proxy navidrome:4533
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Navidrome environment generated."
