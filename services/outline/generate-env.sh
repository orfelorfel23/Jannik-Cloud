#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:-}"

# Generate secure random passwords
SECRET_KEY=$(openssl rand -base64 48 | tr -d '\n' | head -c 32)
UTILS_SECRET=$(openssl rand -base64 48 | tr -d '\n' | head -c 32)
POSTGRES_PASSWORD=$(openssl rand -base64 48 | tr -d '\n' | head -c 32)

cat > "${ENV_FILE}" << EOF
# Outline Configuration
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com

# Secret Keys
SECRET_KEY=${SECRET_KEY}
UTILS_SECRET=${UTILS_SECRET}

# Database
POSTGRES_USER=outline
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=outline
EOF

chmod 600 "${ENV_FILE}"
echo "Generated ${ENV_FILE}"

# Encrypt with age if public key is provided
if [ -n "${AGE_PUBLIC_KEY}" ]; then
    echo "${AGE_PUBLIC_KEY}" | age -r - -o "${ENV_FILE}.age" "${ENV_FILE}"
    echo "Encrypted to ${ENV_FILE}.age"
    echo "You can now safely delete ${ENV_FILE} if desired."
fi
