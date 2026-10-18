#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_hex() { openssl rand -hex "$1"; }
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 64; }

# Vorhandene Secrets beibehalten falls vorhanden
NOTES_API_TOKEN=""
LLM_ENDPOINT="https://api.minimax.io/v1"
LLM_API_KEY=""
LLM_MODEL="MiniMax-M3"
VAULT_SYNC_TOKEN=""

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    NOTES_API_TOKEN=$(grep -E "^NOTES_API_TOKEN=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
    LLM_ENDPOINT=$(grep -E "^LLM_ENDPOINT=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || echo "https://api.minimax.io/v1")
    LLM_API_KEY=$(grep -E "^LLM_API_KEY=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
    LLM_MODEL=$(grep -E "^LLM_MODEL=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || echo "MiniMax-M3")
    VAULT_SYNC_TOKEN=$(grep -E "^VAULT_SYNC_TOKEN=" "${SCRIPT_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
fi

if [[ -z "${NOTES_API_TOKEN}" ]]; then
    NOTES_API_TOKEN=$(generate_password)
fi

cat > "${SCRIPT_DIR}/.env" <<EOF
# Mind-o-Mat Webapp + Notes-API
# Auth: HMAC-SHA256 Bearer-Token fuer Notes-API
NOTES_API_TOKEN=${NOTES_API_TOKEN}
# Erlaubte Origins fuer CORS (kommasepariert)
NOTES_API_ALLOWED_ORIGINS=https://mindomat.orfel.de,https://mind.orfel.de,https://mom.orfel.de

LLM_ENDPOINT=${LLM_ENDPOINT}
LLM_API_KEY=${LLM_API_KEY}
LLM_MODEL=${LLM_MODEL}

# Gitea Auth fuer Vault-Sync (privates Repo)
VAULT_SYNC_TOKEN=${VAULT_SYNC_TOKEN}
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
