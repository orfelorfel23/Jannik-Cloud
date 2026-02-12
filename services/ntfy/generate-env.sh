#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
cat > "${ENV_FILE}" << EOF
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
EOF
chmod 600 "${ENV_FILE}"
echo "Generated Ntfy .env"
