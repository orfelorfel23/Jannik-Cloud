#!/bin/bash
#
# Decrypt all .env.age files to .env
# Usage: ./infrastructure/decrypt-secrets.sh [--remove-encrypted]
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="${REPO_ROOT}/services"
KEYS_DIR="/opt/Jannik-Cloud/keys"
AGE_KEY="${KEYS_DIR}/age-key.txt"
REMOVE_ENCRYPTED=false

if [[ "$1" == "--remove-encrypted" ]]; then
    REMOVE_ENCRYPTED=true
fi

if [[ ! -f "${AGE_KEY}" ]]; then
    echo "ERROR: AGE key not found at ${AGE_KEY}"
    exit 1
fi

export AGE_IDENTITY="${AGE_KEY}"

echo "Starting decryption of all .env.age files..."
echo ""

for service_dir in "${SERVICES_DIR}"/*; do
    if [[ -d "${service_dir}" ]]; then
        service_name=$(basename "${service_dir}")
        env_age_file="${service_dir}/.env.age"
        env_file="${service_dir}/.env"
        
        if [[ -f "${env_age_file}" ]]; then
            echo "Decrypting ${service_name}/.env.age..."
            age -d -i "${AGE_KEY}" "${env_age_file}" > "${env_file}"
            chmod 600 "${env_file}"
            
            if [[ "${REMOVE_ENCRYPTED}" == "true" ]]; then
                rm "${env_age_file}"
                echo "  Removed encrypted file"
            fi
        fi
    fi
done

echo ""
echo "All secrets decrypted successfully!"
