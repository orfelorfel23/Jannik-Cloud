#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
    cat > "${SCRIPT_DIR}/.env" <<EOF
# MelodyMuse — Server environment
# ── Provider API keys — fill these in before re-encrypting ──────────────────
LLM_ENDPOINT=https://api.minimax.chat/v1
LLM_API_KEY=PLACEHOLDER
LLM_MODEL=MiniMax-M3
EOF
    chmod 600 "${SCRIPT_DIR}/.env"
else
    echo ".env already exists, skipping generation."
fi

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "MelodyMuse environment generated."
