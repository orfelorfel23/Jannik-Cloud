#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:-}"

ADMIN_PASSWORD=$(openssl rand -base64 48 | tr -d '\n' | head -c 32)

cat > "${ENV_FILE}" << ENVEOF
# ntfy Configuration
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com

# Admin Password (use 'ntfy user add' command)
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ENVEOF

chmod 600 "${ENV_FILE}"
echo "Generated ${ENV_FILE}"

if [ -n "${AGE_PUBLIC_KEY}" ]; then
    echo "${AGE_PUBLIC_KEY}" | age -r - -o "${ENV_FILE}.age" "${ENV_FILE}"
    echo "Encrypted to ${ENV_FILE}.age"
fi
