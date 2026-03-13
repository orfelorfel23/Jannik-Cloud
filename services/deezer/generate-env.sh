#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

cat > "${SCRIPT_DIR}/.env" <<EOF
# Deezer Downloader
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
NEEDS_POSTGRES=false
DEEZER_ARL=PLACEHOLDER
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/deezer.caddy" <<'EOF'
deezer.orfel.de {
	reverse_proxy deezer:6123
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Deezer Downloader environment generated."
echo ""
echo "=== IMPORTANT ==="
echo "You MUST replace DEEZER_ARL=PLACEHOLDER in .env with your actual Deezer ARL cookie."
echo "See README.md for instructions on how to obtain it."
echo "================="
