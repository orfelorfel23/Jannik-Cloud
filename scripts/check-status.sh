#!/bin/bash
set -euo pipefail

echo "==================================="
echo "Jannik-Cloud Status Check"
echo "==================================="
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    exit 1
else
    echo "✅ Docker is running"
fi

# Check Docker network
if docker network inspect jannik-cloud-net &> /dev/null; then
    echo "✅ Docker network 'jannik-cloud-net' exists"
else
    echo "❌ Docker network 'jannik-cloud-net' not found"
fi

echo ""
echo "Running Containers:"
echo "-----------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Service URLs:"
echo "-----------------------------------"
echo "Outline:        https://outline.orfel.de"
echo "LiteLLM:        https://llm.orfel.de"
echo "Portainer:      https://port.orfel.de"
echo "ownCloud:       https://owncloud.orfel.de"
echo "Nextcloud:      https://nextcloud.orfel.de"
echo "MediaWiki:      https://wiki.orfel.de"
echo "Baserow:        https://br.orfel.de"
echo "Vaultwarden:    https://pw.orfel.de"
echo "LibreChat:      https://chat.orfel.de"
echo "ntfy:           https://ntfy.orfel.de"
echo "n8n:            https://n8n.orfel.de"
echo "Gitea:          https://git.orfel.de"
echo "Home Assistant: https://home.orfel.de"
echo "Stirling PDF:   https://pdf.orfel.de"
