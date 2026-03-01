#!/usr/bin/env bash
# generate-env.sh for PostgreSQL
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }

POSTGRES_PASSWORD="$(generate_password)"

cat > "${SCRIPT_DIR}/.env" <<EOF
# PostgreSQL — Shared Database Server
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
EOF

chmod 600 "${SCRIPT_DIR}/.env"

# Encrypt
if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "PostgreSQL environment generated."
echo "Root password has been set. Keep .env.age safe."
