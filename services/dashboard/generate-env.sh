#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

ENV_FILE="${SCRIPT_DIR}/.env"
AGE_KEY="${SCRIPT_DIR}/../../keys/age-public-key.txt"

cat > "${ENV_FILE}" << 'EOF'
PORT=80
EOF

chmod 600 "${ENV_FILE}"

if [[ -f "${AGE_KEY}" ]]; then
    age -r "$(cat "${AGE_KEY}")" -o "${ENV_FILE}.age" "${ENV_FILE}"
    echo "Encrypted to .env.age"
fi
