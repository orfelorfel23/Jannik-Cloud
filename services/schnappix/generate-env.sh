#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
AGE_PUBLIC_KEY_FILE="${SCRIPT_DIR}/../../keys/age-public-key.txt"
ENV_AGE_FILE="${SCRIPT_DIR}/.env.age"

gen_password() {
    openssl rand -base64 24 | tr -d '/+=' | head -c 24
}

echo "=== Schnappix — Umgebungsvariablen generieren ==="
echo ""

ADMIN_PASSWORD=$(gen_password)
echo "Admin-Passwort generiert: ${ADMIN_PASSWORD}"
echo "(Bitte notieren!)"
echo ""

cat > "${ENV_FILE}" <<EOF
ADMIN_PASSWORD=${ADMIN_PASSWORD}
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
