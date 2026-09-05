#!/usr/bin/env bash
# Mind-o-Mat Vault initialisieren
# Einmalig auf dem VPS ausfuehren, bevor die Webapp startet

set -euo pipefail

VAULT_DIR="/mnt/Jannik-Cloud-Volume-01/mindomat-vault"
TOOL_BIN="/opt/Jannik-Cloud/services/mindomat/webapp/node_modules/.bin/mindomat"

# Falls Vault nicht existiert: initialisieren
if [[ ! -d "$VAULT_DIR" ]]; then
    echo "Initialisiere neuen Vault..."
    git clone https://git.orfel.de/Jannik/Mind-o-Mat-Vault.git "$VAULT_DIR"
else
    echo "Vault existiert bereits, ueberspringe Init."
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
