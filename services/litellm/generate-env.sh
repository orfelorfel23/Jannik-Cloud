#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

cat > "${SCRIPT_DIR}/.env" <<EOF
# LiteLLM — LLM Proxy Gateway
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
DB_NAME=litellm_db
DB_USER=litellm_user
DB_PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
MASTER_KEY=sk-$(generate_hex 32)
SALT_KEY=$(generate_hex 32)
NEEDS_POSTGRES=true
STORE_MODEL_IN_DB=true
# ── Provider API keys — fill these in before re-encrypting ──────────────────
OPENAI_API_KEY=PLACEHOLDER
GEMINI_API_KEY=PLACEHOLDER
MINIMAX_API_KEY=PLACEHOLDER
POE_API_KEY=PLACEHOLDER
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/litellm.caddy" <<'EOF'
llm.orfel.de {
	reverse_proxy litellm:4000
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "LiteLLM environment generated."
