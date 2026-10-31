#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }

DB_USER="solus"
DB_PASSWORD=$(generate_password)
DB_NAME="solus"
DB_HOST="postgres"
DB_PORT="5432"

MINIMAX_API_KEY=""
MINIMAX_MODEL="MiniMax-M2.5"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || echo "${DB_PASSWORD}")
    MINIMAX_API_KEY=$(grep -E "^MINIMAX_API_KEY=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
    MINIMAX_MODEL=$(grep -E "^MINIMAX_MODEL=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || echo "MiniMax-M2.5")
    ADMIN_TOKEN=$(grep -E "^ADMIN_TOKEN=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
elif [[ -f "${REPO_ROOT}/services/tokenwatch/.env" ]]; then
    MINIMAX_API_KEY=$(grep -E "^MINIMAX_API_KEY=" "${REPO_ROOT}/services/tokenwatch/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
fi

# Shared admin token (idempotent: keep existing, generate once if missing).
if [[ -z "${ADMIN_TOKEN}" ]]; then
    ADMIN_TOKEN=$(generate_password)
fi

cat > "${SCRIPT_DIR}/.env" <<EOF
# Solus – KI-only Social Network (PostgreSQL)
PORT=8787

# PostgreSQL (deploy_script.sh erzeugt DB & User automatisch anhand NEEDS_POSTGRES=true)
NEEDS_POSTGRES=true
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# KI Provider
MINIMAX_API_KEY=${MINIMAX_API_KEY}
MINIMAX_MODEL=${MINIMAX_MODEL}

# Shared secret protecting /api/admin/* (generated once, kept on re-runs)
ADMIN_TOKEN=${ADMIN_TOKEN}

# CORS: allowed browser origin (reverse proxy domain)
CORS_ORIGINS=https://solus.orfel.de

# Rate limiting (per IP / minute)
RATE_LIMIT_MAX=300
ADMIN_RATE_MAX=60
EOF

chmod 600 "${SCRIPT_DIR}/.env"

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env -> .env.age"
fi
echo "Solus environment generated."
