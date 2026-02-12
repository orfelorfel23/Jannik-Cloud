#!/bin/bash
#
# Caddy - Generate environment variables
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_AGE_FILE="${SCRIPT_DIR}/.env.age"

# Function to generate strong random string
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-$length
}

# Get public key for AGE (needs to be set beforehand)
AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:-}"

echo "Generating Caddy .env file..."

# Create .env
cat > "${ENV_FILE}" << EOF
# Caddy Reverse Proxy Configuration
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
DOMAIN=orfel.de
EOF

chmod 600 "${ENV_FILE}"
echo "Created: ${ENV_FILE}"

# Encrypt with AGE if key is available
if [[ -n "${AGE_PUBLIC_KEY}" ]]; then
    echo "${AGE_PUBLIC_KEY}" | age -e -R /dev/stdin < "${ENV_FILE}" > "${ENV_AGE_FILE}"
    chmod 600 "${ENV_AGE_FILE}"
    echo "Encrypted: ${ENV_AGE_FILE}"
fi

echo "Done!"
