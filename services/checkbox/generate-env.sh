#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

# MS SQL SA password requires uppercase, lowercase, numbers, and symbols.
# We generate a random 32-char string, and append '1aA!' to guarantee complexity requirements are met.
generate_password() {
    base_pw=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#%^&*' | head -c 28)
    echo "${base_pw}1aA!"
}

cat > "${SCRIPT_DIR}/.env" <<EOF
# Checkbox — MS SQL Server Express
MSSQL_ADDRESS=checkbox.orfel.de,7224
MSSQL_DB_NAME=Niederneuschoenberg
MSSQL_USER=sa
MSSQL_SA_PASSWORD=$(generate_password)
EOF

chmod 600 "${SCRIPT_DIR}/.env"

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Checkbox MS SQL environment generated."
