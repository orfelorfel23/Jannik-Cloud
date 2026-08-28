#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }

# deploy_script.sh automatically reads DB_USER and DB_PASSWORD to create the DB in the shared Postgres.
DB_USER="tokenwatch"
DB_PASSWORD=$(generate_password)
DB_NAME="tokenwatch"

cat > "${SCRIPT_DIR}/.env" <<EOF
# TokenWatch
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}?sslmode=disable

NTFY_URL=https://ntfy.orfel.de/Token-Watch
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/tokenwatch.caddy" <<'EOF'
tokenwatch.orfel.de {
	reverse_proxy 127.0.0.1:3500
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env -> .env.age"
fi
echo "TokenWatch environment generated."
