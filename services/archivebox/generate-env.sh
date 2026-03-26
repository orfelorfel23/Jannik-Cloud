#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"
generate_password() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_hex() { openssl rand -hex "$1"; }

cat > "${SCRIPT_DIR}/.env" <<EOF
# ArchiveBox — Self-hosted internet archiving
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
PASSWORD=$(generate_password)
SECRET_KEY=$(generate_hex 32)
EOF

chmod 600 "${SCRIPT_DIR}/.env"

cat > "${SCRIPT_DIR}/archivebox.caddy" <<'EOF'
archive.orfel.de {
	reverse_proxy archivebox:8000
}
EOF

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi
echo "ArchiveBox environment generated."
