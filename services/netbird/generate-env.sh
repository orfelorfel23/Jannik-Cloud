#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

# Helper for secure generation
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 24; }

# Create initial .env
cat > "${SCRIPT_DIR}/.env" <<EOF
# NetBird — Mesh VPN (Combined Container)
NETBIRD_DOMAIN=vpn.orfel.de
NETBIRD_IP_RANGE=10.23.1.0/23

# Database
NEEDS_POSTGRES=true
DB_NAME=netbird
DB_USER=netbird
DB_PASSWORD=$(generate_password)
EOF

chmod 600 "${SCRIPT_DIR}/.env"

# Encrypt if public key exists
if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "NetBird environment generated."
