#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
    echo "Fehler: ${SCRIPT_DIR}/.env existiert nicht!"
    exit 1
fi

chmod 600 "${SCRIPT_DIR}/.env"

if [[ -f "${AGE_PUB_KEY}" ]]; then
    age -r "$(cat "${AGE_PUB_KEY}")" -o "${SCRIPT_DIR}/.env.age" "${SCRIPT_DIR}/.env"
    echo "Encrypted .env -> .env.age"
fi
echo "DiscordCalle environment ready."
