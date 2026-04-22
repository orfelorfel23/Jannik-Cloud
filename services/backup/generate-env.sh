#!/usr/bin/env bash
###############################################################################
# generate-env.sh for Backup Service
#
# Collects the PostgreSQL password and the rclone Google Drive token,
# then encrypts everything into .env.age like all other services.
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

# --- PostgreSQL password ---
POSTGRES_ENV="${SCRIPT_DIR}/../postgres/.env"
if [[ -f "${POSTGRES_ENV}" ]]; then
    POSTGRES_PASSWORD=$(grep -E "^POSTGRES_PASSWORD=" "${POSTGRES_ENV}" | cut -d= -f2 | tr -d '"')
    echo "✓ Read POSTGRES_PASSWORD from postgres/.env"
else
    echo "WARNING: postgres/.env not found."
    echo -n "Enter the PostgreSQL root password: "
    read -rs POSTGRES_PASSWORD
    echo ""
fi

# --- rclone Google Drive token ---
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Google Drive Authorization                                ║"
echo "║                                                            ║"
echo "║  On your LOCAL machine (with a browser), run:              ║"
echo "║                                                            ║"
echo "║    rclone authorize \"drive\"                                ║"
echo "║                                                            ║"
echo "║  This opens a browser for Google login. After authorizing, ║"
echo "║  rclone prints a JSON token. Copy the ENTIRE JSON block.   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Paste the rclone token JSON (single line, then press Enter):"
read -r RCLONE_DRIVE_TOKEN

if [[ -z "${RCLONE_DRIVE_TOKEN}" ]]; then
    echo "WARNING: No token provided. Backups will fail until you re-run generate-env.sh."
    RCLONE_DRIVE_TOKEN="PASTE_TOKEN_HERE"
fi

# --- Write .env ---
cat > "${SCRIPT_DIR}/.env" <<EOF
# Backup Service — Auto-generated
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
RCLONE_DRIVE_TOKEN=${RCLONE_DRIVE_TOKEN}
EOF

chmod 600 "${SCRIPT_DIR}/.env"

# --- Encrypt ---
if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo ""
echo "✓ Backup environment generated."
echo "  Deploy with: sudo bash /opt/Jannik-Cloud/deploy_script.sh"
