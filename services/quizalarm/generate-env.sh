#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
AGE_PUBLIC_KEY_FILE="${SCRIPT_DIR}/../../keys/age-public-key.txt"
ENV_AGE_FILE="${SCRIPT_DIR}/.env.age"

gen_password() {
    openssl rand -base64 24 | tr -d '/+=' | head -c 24
}

echo "=== Quizalarm — Umgebungsvariablen generieren ==="
echo ""

ADMIN_PASSWORD=$(gen_password)
echo "Admin-Passwort generiert: ${ADMIN_PASSWORD}"
echo "(Bitte notieren!)"
echo ""

read -p "Baserow interne URL [http://baserow:80]: " BASEROW_URL
BASEROW_URL="${BASEROW_URL:-http://baserow:80}"

read -p "Baserow API Token: " BASEROW_TOKEN
if [[ -z "${BASEROW_TOKEN}" ]]; then
    echo "WARNUNG: Kein Token angegeben. Bitte in .env nachtragen und neu verschluesseln."
    BASEROW_TOKEN="DEIN_TOKEN_HIER"
fi

cat > "${ENV_FILE}" <<EOF
ADMIN_PASSWORD=${ADMIN_PASSWORD}
BASEROW_URL=${BASEROW_URL}
BASEROW_TOKEN=${BASEROW_TOKEN}
PORT=7849
CONFIG_PATH=/data/config.json
EOF

echo ""
echo ".env erstellt: ${ENV_FILE}"

if [[ -f "${AGE_PUBLIC_KEY_FILE}" ]]; then
    AGE_PUBLIC_KEY=$(tr -d '[:space:]' < "${AGE_PUBLIC_KEY_FILE}")
    age -r "${AGE_PUBLIC_KEY}" -o "${ENV_AGE_FILE}" "${ENV_FILE}"
    echo ".env.age verschluesselt: ${ENV_AGE_FILE}"
else
    echo "WARNUNG: AGE Public Key nicht gefunden. Verschluesselung uebersprungen."
fi