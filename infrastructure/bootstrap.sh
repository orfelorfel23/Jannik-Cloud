#!/bin/bash
#
# Jannik Cloud Infrastructure Bootstrap Script
# Production-ready deployment for multi-service Docker infrastructure
# Usage: sudo /path/to/infrastructure/bootstrap.sh
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRASTRUCTURE_DIR="${REPO_ROOT}/infrastructure"
SERVICES_DIR="${REPO_ROOT}/services"
KEYS_DIR="/opt/Jannik-Cloud/keys"
AGE_KEY="${KEYS_DIR}/age-key.txt"
DATA_VOLUME="/mnt/Jannik-Cloud-Volume-01"
DOCKER_NETWORK="jannik-cloud-net"

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use: sudo infrastructure/bootstrap.sh)"
    exit 1
fi

log_info "==========================================="
log_info "Jannik Cloud Infrastructure Bootstrap"
log_info "==========================================="
log_info "Repository: ${REPO_ROOT}"
log_info "Data Volume: ${DATA_VOLUME}"
log_info ""

# ===========================
# 1. AGE KEY MANAGEMENT
# ===========================
log_info "Step 1: Checking AGE key..."

mkdir -p "${KEYS_DIR}"
chmod 700 "${KEYS_DIR}"

if [[ ! -f "${AGE_KEY}" ]]; then
    log_warn "AGE private key not found at ${AGE_KEY}"
    echo -e "${YELLOW}Please paste your AGE-SECRET-KEY now (input will be hidden):${NC}"
    read -s -p "> " age_input
    echo ""
    
    if [[ ! "$age_input" =~ ^AGE-SECRET-KEY-[A-Za-z0-9]+$ ]]; then
        log_error "Invalid AGE key format. Must start with 'AGE-SECRET-KEY-'"
        exit 1
    fi
    
    echo "$age_input" > "${AGE_KEY}"
    chmod 600 "${AGE_KEY}"
    log_success "AGE key saved to ${AGE_KEY}"
else
    # Verify existing key format
    if ! grep -q "^AGE-SECRET-KEY-" "${AGE_KEY}" 2>/dev/null; then
        log_error "Invalid AGE key format in existing file"
        exit 1
    fi
    log_success "AGE key verified"
fi

# ===========================
# 2. INSTALL DEPENDENCIES
# ===========================
log_info "Step 2: Installing dependencies..."

# Check and install Docker
if ! command -v docker &> /dev/null; then
    log_warn "Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    bash /tmp/get-docker.sh
    usermod -aG docker jannik || true
    log_success "Docker installed"
else
    log_success "Docker already installed"
fi

# Check and install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    log_warn "Docker Compose plugin not found. Installing..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    log_success "Docker Compose plugin installed"
else
    log_success "Docker Compose plugin already installed"
fi

# Check and install age
if ! command -v age &> /dev/null; then
    log_warn "age not found. Installing..."
    apt-get update -qq
    apt-get install -y -qq age
    log_success "age installed"
else
    log_success "age already installed"
fi

# Check and install fail2ban
if ! command -v fail2ban-client &> /dev/null; then
    log_warn "fail2ban not found. Installing..."
    apt-get update -qq
    apt-get install -y -qq fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban || true
    log_success "fail2ban installed"
else
    log_success "fail2ban already installed"
fi

# ===========================
# 3. CREATE DATA VOLUME
# ===========================
log_info "Step 3: Creating data volume directories..."

if [[ ! -d "${DATA_VOLUME}" ]]; then
    log_error "Data volume ${DATA_VOLUME} does not exist. Please mount it first."
    exit 1
fi

# Create service data directories
mkdir -p "${DATA_VOLUME}"/{caddy,outline,litellm,portainer,owncloud,nextcloud,mediawiki,baserow,vaultwarden,librechat,ntfy,n8n,gitea,homeassistant,stirling-pdf}
chmod 755 "${DATA_VOLUME}"
log_success "Data volume directories created"

# ===========================
# 4. DECRYPT SECRETS
# ===========================
log_info "Step 4: Decrypting service secrets..."

export AGE_IDENTITY="${AGE_KEY}"

for service_dir in "${SERVICES_DIR}"/*; do
    if [[ -d "${service_dir}" ]]; then
        service_name=$(basename "${service_dir}")
        env_file="${service_dir}/.env"
        env_age_file="${service_dir}/.env.age"
        
        if [[ -f "${env_age_file}" ]]; then
            log_info "  Decrypting ${service_name}/.env.age..."
            age -d -i "${AGE_KEY}" "${env_age_file}" > "${env_file}"
            chmod 600 "${env_file}"
            log_success "  ${service_name}/.env decrypted"
        elif [[ ! -f "${env_file}" ]]; then
            log_warn "  ${service_name}/.env not found. Running generate-env.sh..."
            if [[ -f "${service_dir}/generate-env.sh" ]]; then
                cd "${service_dir}"
                bash generate-env.sh
                cd - > /dev/null
            fi
        fi
    fi
done

# ===========================
# 5. CREATE DOCKER NETWORK
# ===========================
log_info "Step 5: Creating Docker network..."

if ! docker network ls | grep -q "${DOCKER_NETWORK}"; then
    docker network create "${DOCKER_NETWORK}"
    log_success "Docker network '${DOCKER_NETWORK}' created"
else
    log_success "Docker network '${DOCKER_NETWORK}' already exists"
fi

# ===========================
# 6. START CADDY (REVERSE PROXY)
# ===========================
log_info "Step 6: Starting Caddy reverse proxy..."

cd "${SERVICES_DIR}/caddy"
docker compose down -v 2>/dev/null || true
docker compose up -d
if docker compose ps | grep -q "caddy.*Up"; then
    log_success "Caddy is running"
else
    log_error "Caddy failed to start"
    exit 1
fi
cd - > /dev/null

# ===========================
# 7. START ALL OTHER SERVICES
# ===========================
log_info "Step 7: Starting all services..."

services_started=0
services_failed=0

for service_dir in "${SERVICES_DIR}"/*; do
    if [[ -d "${service_dir}" ]]; then
        service_name=$(basename "${service_dir}")
        
        # Skip Caddy (already started)
        if [[ "${service_name}" == "caddy" ]]; then
            continue
        fi
        
        if [[ -f "${service_dir}/docker-compose.yml" ]]; then
            log_info "  Starting ${service_name}..."
            cd "${service_dir}"
            docker compose down 2>/dev/null || true
            if docker compose up -d; then
                log_success "  ${service_name} started"
                ((services_started++))
            else
                log_error "  ${service_name} failed to start"
                ((services_failed++))
            fi
            cd - > /dev/null
        fi
    fi
done

# ===========================
# 8. VERIFY DEPLOYMENT
# ===========================
log_info "Step 8: Verifying deployment..."

docker ps --format "table {{.Names}}\t{{.Status}}"

log_info ""
log_success "==========================================="
log_success "Bootstrap Complete!"
log_success "==========================================="
log_success "Services Started: ${services_started}"
if [[ ${services_failed} -gt 0 ]]; then
    log_warn "Services Failed: ${services_failed}"
fi
log_info ""
log_info "Access your services:"
log_info "  Caddy/Reverse Proxy: https://orfel.de"
log_info "  Outline: https://outline.orfel.de"
log_info "  LiteLLM: https://llm.orfel.de"
log_info "  Portainer: https://port.orfel.de"
log_info "  OwnCloud: https://owncloud.orfel.de"
log_info "  NextCloud: https://nextcloud.orfel.de"
log_info "  MediaWiki: https://wiki.orfel.de"
log_info "  Baserow: https://br.orfel.de"
log_info "  Vaultwarden: https://pw.orfel.de"
log_info "  LibreChat: https://chat.orfel.de"
log_info "  Ntfy: https://ntfy.orfel.de"
log_info "  N8N: https://n8n.orfel.de"
log_info "  Gitea: https://git.orfel.de"
log_info "  HomeAssistant: https://home.orfel.de"
log_info "  Stirling PDF: https://pdf.orfel.de"
log_info ""
log_info "View logs: docker logs <service_name>"
log_info "==========================================="

exit 0
