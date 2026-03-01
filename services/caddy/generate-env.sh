#!/usr/bin/env bash
# generate-env.sh for Caddy
# Caddy does not require secrets, but this script creates the placeholder files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

# Caddy has no .env — create an empty one for consistency
cat > "${SCRIPT_DIR}/.env" <<EOF
# Caddy — no secrets required
EOF

# Encrypt
if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env → .env.age"
fi

echo "Caddy environment generated."
