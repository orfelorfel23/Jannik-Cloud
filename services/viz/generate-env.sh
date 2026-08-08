#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
    cat > "${SCRIPT_DIR}/.env" <<EOF
# Viz — Audio Visualizer Studio environment
PORT=849
DATA_DIR=/data
NODE_ENV=production
EOF
    chmod 600 "${SCRIPT_DIR}/.env"
else
    echo ".env already exists, skipping generation."
fi

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Viz environment generated."
