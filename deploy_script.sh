#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jannik-Cloud Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Configuration
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOLUME_PATH="/mnt/Jannik-Cloud-Volume-01"
KEYS_DIR="/opt/Jannik-Cloud/keys"
AGE_KEY_FILE="${KEYS_DIR}/age-key.txt"
DOCKER_NETWORK="jannik-cloud-net"

# Create keys directory
mkdir -p "${KEYS_DIR}"
chmod 700 "${KEYS_DIR}"

# Handle AGE private key
echo -e "${YELLOW}Checking for AGE private key...${NC}"
if [ ! -f "${AGE_KEY_FILE}" ]; then
    echo -e "${YELLOW}AGE private key not found at ${AGE_KEY_FILE}${NC}"
    echo -e "${YELLOW}Please paste your AGE private key (input will be hidden):${NC}"
    read -s AGE_PRIVATE_KEY
    echo ""
    
    if [[ ! "${AGE_PRIVATE_KEY}" =~ ^AGE-SECRET-KEY- ]]; then
        echo -e "${RED}Invalid AGE key format. Key must start with 'AGE-SECRET-KEY-'${NC}"
        exit 1
    fi
    
    echo "${AGE_PRIVATE_KEY}" > "${AGE_KEY_FILE}"
    chmod 600 "${AGE_KEY_FILE}"
    echo -e "${GREEN}AGE key saved securely.${NC}"
else
    # Verify existing key
    if ! grep -q "^AGE-SECRET-KEY-" "${AGE_KEY_FILE}"; then
        echo -e "${RED}Existing AGE key is invalid. Please remove ${AGE_KEY_FILE} and run again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}AGE key found and verified.${NC}"
fi

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt-get update -qq

# Install age if not present
if ! command -v age &> /dev/null; then
    echo -e "${YELLOW}Installing age...${NC}"
    apt-get install -y -qq age
fi

# Install fail2ban if not present
if ! command -v fail2ban-client &> /dev/null; then
    echo -e "${YELLOW}Installing fail2ban...${NC}"
    apt-get install -y -qq fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    apt-get install -y -qq ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker installed successfully.${NC}"
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

# Create volume directory
echo -e "${YELLOW}Setting up persistent volume...${NC}"
mkdir -p "${VOLUME_PATH}"

# Create Docker network
echo -e "${YELLOW}Creating Docker network...${NC}"
if ! docker network inspect "${DOCKER_NETWORK}" &> /dev/null; then
    docker network create "${DOCKER_NETWORK}"
    echo -e "${GREEN}Docker network '${DOCKER_NETWORK}' created.${NC}"
else
    echo -e "${GREEN}Docker network '${DOCKER_NETWORK}' already exists.${NC}"
fi

# Decrypt all .env.age files
echo -e "${YELLOW}Decrypting environment files...${NC}"
cd "${REPO_DIR}"
for env_age_file in $(find services -name ".env.age" -o -name "*.env.age"); do
    env_file="${env_age_file%.age}"
    echo -e "  Decrypting ${env_age_file}..."
    age --decrypt -i "${AGE_KEY_FILE}" -o "${env_file}" "${env_age_file}" 2>/dev/null || {
        echo -e "${RED}Failed to decrypt ${env_age_file}${NC}"
        exit 1
    }
    chmod 600 "${env_file}"
done
echo -e "${GREEN}All environment files decrypted.${NC}"

# Start Caddy first
echo -e "${YELLOW}Starting Caddy reverse proxy...${NC}"
cd "${REPO_DIR}/caddy"
docker compose down 2>/dev/null || true
docker compose up -d
echo -e "${GREEN}Caddy started.${NC}"

# Start all services
echo -e "${YELLOW}Starting all services...${NC}"
for service_dir in "${REPO_DIR}/services/"*/; do
    service_name=$(basename "${service_dir}")
    echo -e "  Starting ${service_name}..."
    cd "${service_dir}"
    docker compose down 2>/dev/null || true
    docker compose up -d
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Services are now available at:"
echo -e "  ${GREEN}https://outline.orfel.de${NC}   - Outline"
echo -e "  ${GREEN}https://llm.orfel.de${NC}       - LiteLLM"
echo -e "  ${GREEN}https://port.orfel.de${NC}      - Portainer"
echo -e "  ${GREEN}https://owncloud.orfel.de${NC}  - ownCloud"
echo -e "  ${GREEN}https://nextcloud.orfel.de${NC} - Nextcloud"
echo -e "  ${GREEN}https://wiki.orfel.de${NC}      - MediaWiki"
echo -e "  ${GREEN}https://br.orfel.de${NC}        - Baserow"
echo -e "  ${GREEN}https://pw.orfel.de${NC}        - Vaultwarden"
echo -e "  ${GREEN}https://chat.orfel.de${NC}      - LibreChat"
echo -e "  ${GREEN}https://ntfy.orfel.de${NC}      - ntfy"
echo -e "  ${GREEN}https://n8n.orfel.de${NC}       - n8n"
echo -e "  ${GREEN}https://git.orfel.de${NC}       - Gitea"
echo -e "  ${GREEN}https://home.orfel.de${NC}      - Home Assistant"
echo -e "  ${GREEN}https://pdf.orfel.de${NC}       - Stirling PDF"
echo ""
