#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

# Helper for secure generation
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 24; }
generate_secret() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }

# Create initial .env
cat > "${SCRIPT_DIR}/.env" <<EOF
# NetBird — Mesh VPN
NETBIRD_DOMAIN=vpn.orfel.de
NETBIRD_IP_RANGE=10.23.1.0/23
NETBIRD_VERSION=latest

# Database
NEEDS_POSTGRES=true
DB_NAME=netbird
DB_USER=netbird
DB_PASSWORD=$(generate_password)

# Netbird Components Secrets
NETBIRD_ENCRYPTION_KEY="$(openssl rand -base64 32)"
NETBIRD_SIGNAL_SECRET="$(openssl rand -base64 32)"
NETBIRD_RELAY_AUTH_SECRET="$(openssl rand -base64 32)"
COTURN_SECRET="$(generate_secret)"

# OIDC Setup (Embedded)
NETBIRD_AUTH_CLIENT_ID=netbird-dashboard
NETBIRD_AUTH_AUDIENCE=netbird-dashboard
NETBIRD_AUTH_DEVICE_AUTH_CLIENT_ID=netbird-dashboard
NETBIRD_AUTH_SUPPORTED_SCOPES="openid profile email"

EOF

# Replace secrets in the turnserver config if it exists or generate it
chmod 600 "${SCRIPT_DIR}/.env"

# Encrypt if public key exists
if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "NetBird environment generated."
