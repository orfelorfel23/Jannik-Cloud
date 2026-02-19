#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo)"
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================"
echo "Jannik-Cloud Service Credentials"
echo "========================================"
echo ""
echo "WARNING: This information is sensitive!"
echo ""

for service_dir in "${REPO_DIR}/services/"*/; do
    service_name=$(basename "${service_dir}")
    env_file="${service_dir}.env"
    
    if [ -f "${env_file}" ]; then
        echo "----------------------------------------"
        echo "Service: ${service_name}"
        echo "----------------------------------------"
        cat "${env_file}"
        echo ""
    fi
done
