#!/bin/bash
set -euo pipefail

echo "Generating AGE key pair..."
age-keygen -o age-key.txt

echo ""
echo "================================================================"
echo "AGE Key Generated!"
echo "================================================================"
echo ""
echo "PRIVATE KEY saved to: age-key.txt"
echo "Keep this file SECURE and BACKED UP!"
echo ""
echo "Your PUBLIC KEY is:"
grep "# public key:" age-key.txt | sed 's/# public key: //'
echo ""
echo "Share the public key with team members to encrypt secrets."
echo "Store the private key in /opt/Jannik-Cloud/keys/age-key.txt on the server."
echo ""
