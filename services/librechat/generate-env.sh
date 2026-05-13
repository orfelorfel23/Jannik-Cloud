#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
LITELLM_ENV="${SCRIPT_DIR}/../litellm/.env"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

# Auto-read LITELLM_API_KEY from the LiteLLM service .env
if [[ -f "${LITELLM_ENV}" ]]; then
    LITELLM_API_KEY="$(grep -E "^MASTER_KEY=" "${LITELLM_ENV}" | cut -d= -f2 | tr -d '[:space:]')"
    echo "✓ LITELLM_API_KEY read from litellm/.env"
else
    LITELLM_API_KEY="PLACEHOLDER"
    echo "⚠ litellm/.env not found — run litellm/generate-env.sh first, then re-run this script."
fi

cat > "${SCRIPT_DIR}/.env" <<EOF
# LibreChat — AI Chat Interface
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
DB_NAME=librechat_db
DB_USER=librechat_user
DB_PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
CREDS_IV=$(generate_hex 8)
JWT_SECRET=$(generate_hex 32)
JWT_REFRESH_SECRET=$(generate_hex 32)
NEEDS_POSTGRES=true
LITELLM_API_KEY=${LITELLM_API_KEY}
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/librechat.caddy" <<'EOF'
chat.orfel.de {
	reverse_proxy librechat:3080
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "LibreChat environment generated."
