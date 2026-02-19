#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <age-public-key>"
    echo "Example: $0 age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    exit 1
fi

AGE_PUBLIC_KEY="$1"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "Encrypting all .env files with AGE public key..."
for env_file in $(find services caddy -name ".env" ! -name "*.age"); do
    echo "  Encrypting ${env_file}..."
    echo "${AGE_PUBLIC_KEY}" | age -r - -o "${env_file}.age" "${env_file}"
done

echo ""
echo "All .env files encrypted to .env.age"
echo "You can now safely commit .env.age files to git."
echo ""
echo "To remove plaintext .env files (DANGEROUS - make sure .env.age files work first!):"
echo "  find services caddy -name '.env' ! -name '*.age' -delete"
echo ""
