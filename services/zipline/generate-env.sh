#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

DB_PASSWORD="$(generate_password)"

cat > "${SCRIPT_DIR}/.env" <<EOF
# Zipline — URL Shortener / File Host
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
NEEDS_POSTGRES=true
DB_NAME=zipline_db
DB_USER=zipline_user
DB_PASSWORD=${DB_PASSWORD}
CORE_SECRET=$(generate_hex 32)
CORE_DATABASE_URL=postgresql://zipline_user:${DB_PASSWORD}@postgres:5432/zipline_db
REQUIRED_UID=1000
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/zipline.caddy" <<'EOF'
short.orfel.de {
	reverse_proxy zipline:3000
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Zipline environment generated."
