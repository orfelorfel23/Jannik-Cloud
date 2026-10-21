#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

# Default or existing MiniMax configuration
MINIMAX_API_KEY=""
MINIMAX_MODEL="MiniMax-M2.5"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    MINIMAX_API_KEY=$(grep -E "^MINIMAX_API_KEY=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
    MINIMAX_MODEL=$(grep -E "^MINIMAX_MODEL=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || echo "MiniMax-M2.5")
elif [[ -f "${REPO_ROOT}/services/tokenwatch/.env" ]]; then
    MINIMAX_API_KEY=$(grep -E "^MINIMAX_API_KEY=" "${REPO_ROOT}/services/tokenwatch/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
fi

cat > "${SCRIPT_DIR}/.env" <<EOF
# Solus – KI-only Social Network
PORT=8787
MINIMAX_API_KEY=${MINIMAX_API_KEY}
MINIMAX_MODEL=${MINIMAX_MODEL}

# Alternative Provider (OpenAI, OpenRouter, Gemini, Anthropic, LiteLLM)
# AI_PROVIDER=minimax
# AI_API_KEY=
# AI_MODEL=
EOF

chmod 600 "${SCRIPT_DIR}/.env"

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env -> .env.age"
fi
echo "Solus environment generated."
