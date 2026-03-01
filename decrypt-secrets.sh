#!/usr/bin/env bash
###############################################################################
# decrypt-secrets.sh — Standalone helper to decrypt all .env.age files
# Usage:  sudo bash /opt/Jannik-Cloud/decrypt-secrets.sh
###############################################################################
set -euo pipefail

REPO_DIR="/opt/Jannik-Cloud"
AGE_PRIVATE_KEY="${REPO_DIR}/keys/age-key.txt"
SERVICES_DIR="${REPO_DIR}/services"

log()  { echo -e "\e[32m[DECRYPT]\e[0m $*"; }
err()  { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }
die()  { err "$@"; exit 1; }

# Check AGE key
if [[ ! -f "${AGE_PRIVATE_KEY}" ]]; then
    die "AGE private key not found at ${AGE_PRIVATE_KEY}"
fi

if ! head -1 "${AGE_PRIVATE_KEY}" | grep -q "^AGE-SECRET-KEY-"; then
    die "Invalid AGE private key format."
fi

log "Decrypting all .env.age files..."

count=0
for env_age in "${SERVICES_DIR}"/*/.env.age; do
    if [[ ! -f "${env_age}" ]]; then
        continue
    fi

    svc_dir="$(dirname "${env_age}")"
    svc_name="$(basename "${svc_dir}")"
    env_file="${svc_dir}/.env"

    age --decrypt -i "${AGE_PRIVATE_KEY}" -o "${env_file}" "${env_age}"
    chmod 600 "${env_file}"
    log "  ✓ ${svc_name}/.env"
    count=$((count + 1))
done

log "Done. Decrypted ${count} file(s)."
