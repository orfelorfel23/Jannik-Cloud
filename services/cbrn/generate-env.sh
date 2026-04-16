#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

generate_password() { openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20; }
generate_jwt() { openssl rand -hex 32; }

# Will use the default postgres credentials from the environment, assuming content_vault DB and user
POSTGRES_USER="content_vault"
POSTGRES_DB="content_vault"
POSTGRES_HOST="postgres"
POSTGRES_PORT="5432"

if [ -f "${SCRIPT_DIR}/.env" ]; then
    echo ".env already exists, won't overwrite."
    exit 0
fi

# We need a password for the content_vault Postgres user
DB_PASSWORD=$(generate_password)

cat > "${SCRIPT_DIR}/.env" <<EOF
# CBRN (Content-Vault) Environment
PORT=3001
CORS_ORIGIN=https://admin.cbrn.orfel.de,https://cbrn.orfel.de
ADMIN_PASSWORD=$(generate_password)
JWT_SECRET=$(generate_jwt)

# Database
POSTGRES_DB_USER=${POSTGRES_USER}
POSTGRES_DB_PASSWORD=${DB_PASSWORD}
DATABASE_URL=postgres://${POSTGRES_USER}:${DB_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/cbrn.caddy" <<'EOF'
# Frontend View
cbrn.orfel.de {
    reverse_proxy 127.0.0.1:2276
}

# Frontend Admin
admin.cbrn.orfel.de {
    reverse_proxy 127.0.0.1:2276
}

# Backend API
api.cbrn.orfel.de {
    reverse_proxy cbrn-backend:3001
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "CBRN environment generated."
echo "CRITICAL: You must manually create the Postgres user and database on the Postgres server!"
echo "User: ${POSTGRES_USER}"
echo "Password: ${DB_PASSWORD}"
echo "Database: ${POSTGRES_DB}"
