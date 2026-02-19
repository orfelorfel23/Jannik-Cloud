#!/bin/bash
set -euo pipefail

AGE_KEY_FILE="${1:-/opt/Jannik-Cloud/keys/age-key.txt}"

if [ ! -f "${AGE_KEY_FILE}" ]; then
    echo "ERROR: AGE key not found at ${AGE_KEY_FILE}"
    echo "Usage: $0 [path-to-age-key.txt]"
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "Decrypting all .env.age files..."
for env_age_file in $(find . -name "*.env.age"); do
    env_file="${env_age_file%.age}"
    echo "  ${env_age_file} -> ${env_file}"
    age --decrypt -i "${AGE_KEY_FILE}" -o "${env_file}" "${env_age_file}"
    chmod 600 "${env_file}"
done

echo "Done!"
