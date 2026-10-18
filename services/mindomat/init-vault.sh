#!/usr/bin/env bash
# Mind-o-Mat Vault initialisieren
# Einmalig auf dem VPS ausfuehren, bevor die Webapp startet

set -euo pipefail
export GIT_TERMINAL_PROMPT=0

SVC_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="/mnt/Jannik-Cloud-Volume-01/mindomat-vault"
VAULT_REPO_URL="https://git.orfel.de/Jannik/Mind-o-Mat-Vault.git"
TOOL_BIN="/opt/Jannik-Cloud/services/mindomat/webapp/node_modules/.bin/mindomat"

# Lese VAULT_SYNC_TOKEN aus Environment oder .env falls vorhanden
VAULT_SYNC_TOKEN="${VAULT_SYNC_TOKEN:-}"
if [[ -z "${VAULT_SYNC_TOKEN}" && -f "${SVC_DIR}/.env" ]]; then
    VAULT_SYNC_TOKEN=$(grep -E "^VAULT_SYNC_TOKEN=" "${SVC_DIR}/.env" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]"' || true)
fi

AUTH_REPO_URL="${VAULT_REPO_URL}"
if [[ -n "${VAULT_SYNC_TOKEN}" ]]; then
    AUTH_REPO_URL="https://${VAULT_SYNC_TOKEN}@git.orfel.de/Jannik/Mind-o-Mat-Vault.git"
fi

# Falls Vault nicht existiert oder kein Git-Repo ist: initialisieren
if [[ ! -d "$VAULT_DIR/.git" ]]; then
    echo "Initialisiere Vault aus Git-Repository..."
    rm -rf "$VAULT_DIR"
    git clone "${AUTH_REPO_URL}" "$VAULT_DIR"
else
    echo "Vault existiert bereits, aktualisiere mit git pull..."
    cd "$VAULT_DIR"
    git remote set-url origin "${AUTH_REPO_URL}" 2>/dev/null || true
    git pull origin main || true
fi

# Alle 12 Standardordner anlegen (falls nicht da)
for d in "00_Inbox" "00_Inbox/Verarbeitet" "00_Inbox/Problemfaelle" \
         "01_Daily" "10_Wiki" "10_Wiki/Seiten" "20_Projekte" \
         "90_Templates" "99_System" "99_System/Skripte" \
         "99_System/Logs" "99_System/Cache"; do
    mkdir -p "$VAULT_DIR/$d"
done

# Konfig.md anlegen (falls nicht da)
if [[ ! -f "$VAULT_DIR/99_System/Konfig.md" ]]; then
    cat > "$VAULT_DIR/99_System/Konfig.md" <<'EOF'
---
veraltet_schwellwert_monate: 12
token_budget_default: 4000
token_budget_hardcap: false
qmd_cache_pfad: 99_System/Cache
sync_remote: https://git.orfel.de/Jannik/Mind-o-Mat-Vault.git
ki_provider: minimax
ki_modell: MiniMax-M3
ki_api_url: https://api.minimaxi.chat/v1
ki_api_key_env: MINIMAX_API_KEY
---
EOF
    echo "Konfig.md angelegt"
fi

echo "Vault ist bereit: $VAULT_DIR"
echo "  Ordner: 12 (Standardstruktur)"
echo "  Konfig: $VAULT_DIR/99_System/Konfig.md"
