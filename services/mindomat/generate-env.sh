#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_hex() { openssl rand -hex "$1"; }
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 64; }

cat > "${SCRIPT_DIR}/.env" <<EOF
# Mind-o-Mat Webapp + Notes-API
# Auth: HMAC-SHA256 Bearer-Token fuer Notes-API
NOTES_API_TOKEN=$(generate_password)
# Erlaubte Origins fuer CORS (kommasepariert)
NOTES_API_ALLOWED_ORIGINS=https://mindomat.orfel.de,https://vault.orfel.de
EOF

chmod 600 "${SCRIPT_DIR}/.env"

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "Mind-o-Mat environment generated."

cat <<'INFO'

WICHTIGE NAECHSTE SCHRITTE:
1. Vault initialisieren (einmalig):
   - Auf dem VPS: bash /opt/Jannik-Cloud/services/mindomat/init-vault.sh
   - Oder: manuell git clone des Vault-Repos nach
     /mnt/Jannik-Cloud-Volume-01/mindomat-vault

2. QMD-Embeddings generieren (einmalig nach Vault-Init):
   - docker compose exec qmd qmd collection add /vault/00_Inbox --name inbox
   - docker compose exec qmd qmd collection add /vault/10_Wiki --name wiki
   - docker compose exec qmd qmd embed

3. Notes-API-Token generieren (einmalig fuer PWA-Auth):
   - Token aus NOTES_API_TOKEN ableiten
   - In Webapp-Settings hinterlegen

INFO
