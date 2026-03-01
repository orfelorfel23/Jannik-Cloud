#!/usr/bin/env bash
# generate-env.sh for Redis
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

cat > "${SCRIPT_DIR}/.env" <<EOF
# Redis — no password (internal network only)
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
EOF

chmod 600 "${SCRIPT_DIR}/.env"

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "Redis environment generated."
