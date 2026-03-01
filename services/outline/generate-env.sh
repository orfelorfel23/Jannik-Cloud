#!/usr/bin/env bash
# generate-env.sh for Outline
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

cat > "${SCRIPT_DIR}/.env" <<EOF
# Outline — Wiki & Knowledge Base
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
DB_NAME=outline_db
DB_USER=outline_user
DB_PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
UTILS_SECRET=$(generate_hex 32)
NEEDS_POSTGRES=true
GOOGLE_CLIENT_ID=PLACEHOLDER
GOOGLE_CLIENT_SECRET=PLACEHOLDER
EOF

chmod 600 "${SCRIPT_DIR}/.env"

# Generate Caddy fragment
cat > "${SCRIPT_DIR}/outline.caddy" <<'EOF'
outline.orfel.de {
	reverse_proxy outline:688
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "Outline environment generated."
