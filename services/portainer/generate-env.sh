#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
generate_password() { openssl rand -base64 $((${1:-32} * 3 / 4)) | tr -d "=+/" | cut -c1-${1:-32}; }
cat > "${ENV_FILE}" << EOF
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
ADMIN_PASSWORD=$(generate_password 32)
EOF
chmod 600 "${ENV_FILE}"
echo "Generated Portainer .env"
