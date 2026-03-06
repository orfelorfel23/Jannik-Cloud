#!/usr/bin/env bash
###############################################################################
# Jannik-Cloud — Master Deploy Script
# Fully idempotent. Safe to re-run at any time.
# Usage:  sudo bash /opt/Jannik-Cloud/deploy_script.sh
###############################################################################
set -euo pipefail

REPO_DIR="/opt/Jannik-Cloud"
GIT_REPO_URL="https://github.com/orfelorfel23/Jannik-Cloud.git"
VOLUME_BASE="/mnt/Jannik-Cloud-Volume-01"
DOCKER_NETWORK="jannik-cloud-net"
SERVICES_DIR="${REPO_DIR}/services"
AGE_PRIVATE_KEY="${REPO_DIR}/keys/age-key.txt"
CADDY_FRAGMENTS_DIR="${VOLUME_BASE}/caddy/fragments"
POSTGRES_CONTAINER="postgres"
REDIS_CONTAINER="redis"

# Prefix used by all project containers (docker compose project name)
PROJECT_PREFIX="jannik-cloud"

# Infrastructure services that are started in a specific order
INFRA_SERVICES=("postgres" "redis" "caddy")

###############################################################################
# Helpers
###############################################################################
log()  { echo -e "\e[32m[DEPLOY]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }
die()  { err "$@"; exit 1; }

is_active_service() {
    local svc_dir="$1"
    [[ -f "${svc_dir}/docker-compose.yml" && -f "${svc_dir}/service.enabled" ]]
}

###############################################################################
# 1. Install missing packages
###############################################################################
install_packages() {
    log "Checking required packages..."

    # Docker
    if ! command -v docker &>/dev/null; then
        log "Installing Docker..."
        apt-get update -qq
        apt-get install -y -qq ca-certificates curl gnupg lsb-release
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -qq
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable --now docker
    else
        log "Docker already installed."
    fi

    # Docker Compose plugin
    if ! docker compose version &>/dev/null; then
        log "Installing Docker Compose plugin..."
        apt-get update -qq
        apt-get install -y -qq docker-compose-plugin
    else
        log "Docker Compose plugin already installed."
    fi

    # age
    if ! command -v age &>/dev/null; then
        log "Installing age..."
        apt-get update -qq
        apt-get install -y -qq age
    else
        log "age already installed."
    fi

    # fail2ban
    if ! command -v fail2ban-client &>/dev/null; then
        log "Installing fail2ban..."
        apt-get update -qq
        apt-get install -y -qq fail2ban
    else
        log "fail2ban already installed."
    fi
}

###############################################################################
# 2. Enable fail2ban for SSH
###############################################################################
setup_fail2ban() {
    log "Configuring fail2ban for SSH..."
    cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 5
bantime  = 3600
findtime = 600
EOF
    systemctl enable --now fail2ban
    systemctl restart fail2ban
    log "fail2ban is active."
}

###############################################################################
# 3. Handle AGE private key
###############################################################################
handle_age_key() {
    log "Checking AGE private key..."
    mkdir -p "$(dirname "${AGE_PRIVATE_KEY}")"

    if [[ ! -f "${AGE_PRIVATE_KEY}" ]]; then
        warn "AGE private key not found."
        echo -n "Please paste your AGE private key now (input hidden): "
        read -rs age_key_input
        echo ""
        if [[ -z "${age_key_input}" ]]; then
            die "No key provided. Aborting."
        fi
        echo "${age_key_input}" > "${AGE_PRIVATE_KEY}"
        chmod 600 "${AGE_PRIVATE_KEY}"
        log "AGE private key saved."
    fi

    # Validate key format
    if ! head -1 "${AGE_PRIVATE_KEY}" | grep -q "^AGE-SECRET-KEY-"; then
        die "Invalid AGE private key format. Must start with AGE-SECRET-KEY-"
    fi
    chmod 600 "${AGE_PRIVATE_KEY}"
    log "AGE private key is valid."
}

###############################################################################
# 4. Git clone / pull
###############################################################################
update_repo() {
    log "Updating repository..."
    if [[ ! -d "${REPO_DIR}/.git" ]]; then
        log "No .git directory found — cloning repository for the first time..."
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        git clone "${GIT_REPO_URL}" "${tmp_dir}/repo"
        # Copy repo contents over, preserving local-only files (e.g. keys/age-key.txt)
        rsync -a --ignore-existing "${tmp_dir}/repo/" "${REPO_DIR}/"
        # Now copy .git so subsequent runs can use git pull
        cp -a "${tmp_dir}/repo/.git" "${REPO_DIR}/.git"
        rm -rf "${tmp_dir}"
        # Reset working tree to match remote (picks up any files we missed)
        cd "${REPO_DIR}"
        git checkout -- . 2>/dev/null || true
        log "Repository cloned successfully."
    else
        cd "${REPO_DIR}"
        git fetch origin
        git reset --hard origin/main || git reset --hard origin/master || true
        log "Repository updated via git pull."
    fi
}

###############################################################################
# 5. Docker network
###############################################################################
ensure_network() {
    if ! docker network inspect "${DOCKER_NETWORK}" &>/dev/null; then
        log "Creating Docker network: ${DOCKER_NETWORK}"
        docker network create "${DOCKER_NETWORK}"
    else
        log "Docker network '${DOCKER_NETWORK}' already exists."
    fi
}

###############################################################################
# 6-7. Discover active services & clean up deactivated ones
###############################################################################
discover_services() {
    ACTIVE_SERVICES=()
    for svc_dir in "${SERVICES_DIR}"/*/; do
        svc_name="$(basename "${svc_dir}")"
        if is_active_service "${svc_dir}"; then
            ACTIVE_SERVICES+=("${svc_name}")
        fi
    done
    log "Active services: ${ACTIVE_SERVICES[*]}"
}

cleanup_deactivated() {
    log "Checking for deactivated services to clean up..."
    # Get all running containers with our project label
    local running_containers
    running_containers=$(docker ps --format '{{.Names}}' 2>/dev/null || true)

    for svc_dir in "${SERVICES_DIR}"/*/; do
        svc_name="$(basename "${svc_dir}")"
        if ! is_active_service "${svc_dir}" && [[ -f "${svc_dir}/docker-compose.yml" ]]; then
            # Check if this service has running containers
            if echo "${running_containers}" | grep -q "${svc_name}"; then
                log "Stopping deactivated service: ${svc_name}"
                cd "${svc_dir}"
                docker compose down --remove-orphans 2>/dev/null || true
            fi
        fi
    done
}

###############################################################################
# 8. Stop all running service containers
###############################################################################
stop_all_services() {
    log "Stopping all currently running service containers..."
    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        local svc_dir="${SERVICES_DIR}/${svc_name}"
        cd "${svc_dir}"
        docker compose down --remove-orphans 2>/dev/null || true
    done
    log "All services stopped."
}

###############################################################################
# 9. Decrypt .env.age files
###############################################################################
decrypt_envs() {
    log "Decrypting .env.age files..."
    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        local svc_dir="${SERVICES_DIR}/${svc_name}"
        local env_age="${svc_dir}/.env.age"
        local env_file="${svc_dir}/.env"
        if [[ -f "${env_age}" ]]; then
            age --decrypt -i "${AGE_PRIVATE_KEY}" -o "${env_file}" "${env_age}"
            chmod 600 "${env_file}"
            log "  Decrypted: ${svc_name}/.env"
        fi
    done
}

###############################################################################
# 10. Create persistent volume directories
###############################################################################
create_volumes() {
    log "Creating persistent volume directories..."
    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        local vol_dir="${VOLUME_BASE}/${svc_name}"
        mkdir -p "${vol_dir}"
        log "  ${vol_dir}"
    done
}

###############################################################################
# 11. Assemble Caddy fragments
###############################################################################
assemble_caddy_fragments() {
    log "Assembling Caddy fragments..."
    mkdir -p "${CADDY_FRAGMENTS_DIR}"
    # Remove old fragments
    rm -f "${CADDY_FRAGMENTS_DIR}"/*.caddy

    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        local svc_dir="${SERVICES_DIR}/${svc_name}"
        local caddy_file="${svc_dir}/${svc_name}.caddy"
        if [[ -f "${caddy_file}" ]]; then
            cp "${caddy_file}" "${CADDY_FRAGMENTS_DIR}/"
            log "  Copied: ${svc_name}.caddy"
        fi
    done
}

###############################################################################
# 12. Pull latest Docker images
###############################################################################
pull_images() {
    log "Pulling latest Docker images for all active services..."
    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        local svc_dir="${SERVICES_DIR}/${svc_name}"
        cd "${svc_dir}"
        log "  Pulling ${svc_name}..."
        timeout 120 docker compose pull 2>&1 || warn "  Pull failed/timed out for ${svc_name} (will use cached image if available)"
    done
}

###############################################################################
# 13. Start infrastructure services
###############################################################################
start_infra() {
    # Start PostgreSQL
    if [[ " ${ACTIVE_SERVICES[*]} " =~ " postgres " ]]; then
        log "Starting PostgreSQL..."
        cd "${SERVICES_DIR}/postgres"
        docker compose up -d --remove-orphans
        wait_for_postgres
    fi

    # Start Redis
    if [[ " ${ACTIVE_SERVICES[*]} " =~ " redis " ]]; then
        log "Starting Redis..."
        cd "${SERVICES_DIR}/redis"
        docker compose up -d --remove-orphans
    fi
}

wait_for_postgres() {
    log "Waiting for PostgreSQL to be healthy..."
    local retries=30
    local count=0
    while ! docker exec "${POSTGRES_CONTAINER}" pg_isready -U postgres &>/dev/null; do
        count=$((count + 1))
        if [[ ${count} -ge ${retries} ]]; then
            die "PostgreSQL did not become healthy within ${retries} attempts."
        fi
        log "  Waiting... (${count}/${retries})"
        sleep 2
    done
    log "PostgreSQL is healthy."
}

###############################################################################
# 14. Auto-create PostgreSQL databases and users
###############################################################################
create_postgres_dbs() {
    log "Creating PostgreSQL databases and users for services..."
    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        local svc_dir="${SERVICES_DIR}/${svc_name}"
        local env_file="${svc_dir}/.env"

        # Skip if no .env or NEEDS_POSTGRES is not set
        if [[ ! -f "${env_file}" ]]; then
            continue
        fi

        local needs_pg
        needs_pg=$(grep -E "^NEEDS_POSTGRES=" "${env_file}" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]"' || true)
        if [[ "${needs_pg}" != "true" ]]; then
            continue
        fi

        # Read DB credentials from service .env
        local db_name db_user db_pass
        db_name=$(grep -E "^DB_NAME=" "${env_file}" | cut -d= -f2 | tr -d '[:space:]"' || echo "${svc_name}_db")
        db_user=$(grep -E "^DB_USER=" "${env_file}" | cut -d= -f2 | tr -d '[:space:]"' || echo "${svc_name}_user")
        db_pass=$(grep -E "^DB_PASSWORD=" "${env_file}" | cut -d= -f2 | tr -d '"' || true)

        if [[ -z "${db_pass}" ]]; then
            warn "  No DB_PASSWORD found for ${svc_name}, skipping DB creation."
            continue
        fi

        log "  Creating DB '${db_name}' and user '${db_user}' for ${svc_name}..."

        # Create user if not exists, update password
        docker exec "${POSTGRES_CONTAINER}" psql -U postgres -c \
            "DO \$\$ BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${db_user}') THEN
                    CREATE ROLE ${db_user} WITH LOGIN PASSWORD '${db_pass}';
                ELSE
                    ALTER ROLE ${db_user} WITH PASSWORD '${db_pass}';
                END IF;
            END \$\$;" 2>/dev/null

        # Create database if not exists
        docker exec "${POSTGRES_CONTAINER}" psql -U postgres -c \
            "SELECT 1 FROM pg_database WHERE datname = '${db_name}'" | grep -q 1 || \
            docker exec "${POSTGRES_CONTAINER}" psql -U postgres -c \
            "CREATE DATABASE ${db_name} OWNER ${db_user};" 2>/dev/null

        # Grant privileges
        docker exec "${POSTGRES_CONTAINER}" psql -U postgres -c \
            "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};" 2>/dev/null

        log "  ✓ ${svc_name}: DB=${db_name}, User=${db_user}"
    done
}

###############################################################################
# 15. Start Caddy, then remaining services
###############################################################################
start_caddy() {
    if [[ " ${ACTIVE_SERVICES[*]} " =~ " caddy " ]]; then
        log "Starting Caddy..."
        cd "${SERVICES_DIR}/caddy"
        docker compose up -d --remove-orphans
    fi
}

start_remaining() {
    log "Starting remaining services..."
    for svc_name in "${ACTIVE_SERVICES[@]}"; do
        # Skip infra services (already started)
        if [[ " ${INFRA_SERVICES[*]} " =~ " ${svc_name} " ]]; then
            continue
        fi
        log "  Starting ${svc_name}..."
        cd "${SERVICES_DIR}/${svc_name}"
        docker compose up -d --remove-orphans
    done
}

###############################################################################
# MAIN
###############################################################################
main() {
    log "=========================================="
    log "  Jannik-Cloud Deploy Script"
    log "=========================================="

    if [[ "$(id -u)" -ne 0 ]]; then
        die "This script must be run as root (sudo)."
    fi

    install_packages
    setup_fail2ban
    handle_age_key
    update_repo
    ensure_network
    discover_services
    cleanup_deactivated
    stop_all_services
    decrypt_envs
    create_volumes
    assemble_caddy_fragments
    pull_images
    start_infra
    create_postgres_dbs
    start_caddy
    start_remaining

    log "=========================================="
    log "  Deployment complete!"
    log "=========================================="
    log "Active services: ${ACTIVE_SERVICES[*]}"
}

main "$@"
