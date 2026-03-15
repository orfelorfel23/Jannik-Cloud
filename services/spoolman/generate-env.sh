#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

DB_PASSWORD="$(generate_password)"

cat > "${SCRIPT_DIR}/.env" <<EOF
# Spoolman — 3D Printer Filament Manager
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
NEEDS_POSTGRES=true
DB_NAME=spoolman_db
DB_USER=spoolman_user
DB_PASSWORD=${DB_PASSWORD}
SPOOLMAN_DB_URL=postgresql://spoolman_user:${DB_PASSWORD}@postgres:5432/spoolman_db
REQUIRED_UID=1000
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/spoolman.caddy" <<'EOF'
3d.orfel.de {
	reverse_proxy spoolman:8000
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Spoolman environment generated."
