#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
generate_password() { openssl rand -base64 $((${1:-32} * 3 / 4)) | tr -d "=+/" | cut -c1-${1:-32}; }
cat > "${ENV_FILE}" << EOF
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
OPENAI_API_KEY=$(generate_password 48)
ANTHROPIC_API_KEY=$(generate_password 48)
GOOGLE_API_KEY=$(generate_password 48)
DB_USER=litellm_user
DB_PASSWORD=$(generate_password 32)
LITELLM_MASTER_KEY=$(generate_password 32)
EOF
chmod 600 "${ENV_FILE}"
echo "Generated Outline .env"
