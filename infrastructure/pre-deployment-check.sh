#!/bin/bash
#
# Jannik Cloud Infrastructure - Pre-Deployment Checklist
# Run this before executing bootstrap.sh
#

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "Jannik Cloud - Pre-Deployment Checklist"
echo -e "======================================${NC}\n"

checks_passed=0
checks_failed=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((checks_passed++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((checks_failed++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# System Checks
echo -e "${BLUE}System Requirements:${NC}"

# OS Check
if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    check_pass "Ubuntu OS detected"
else
    check_fail "Not Ubuntu (this setup is tested on Ubuntu 24 LTS)"
fi

# Root access
if [[ $EUID -eq 0 ]]; then
    check_pass "Running as root"
else
    check_warn "Not running as root. Some checks may fail. Run with: sudo $0"
fi

# RAM
ram_gb=$(free -h | awk '/^Mem:/ {print $2}' | sed 's/G//')
if (( $(echo "$ram_gb >= 4" | bc -l) )); then
    check_pass "RAM: ${ram_gb}GB (4GB+ required)"
else
    check_fail "RAM: ${ram_gb}GB (minimum 4GB required, 8GB+ recommended)"
fi

# Storage
echo ""
echo -e "${BLUE}Storage & Volume:${NC}"

if [[ -d "/mnt/Jannik-Cloud-Volume-01" ]]; then
    volume_size=$(du -s /mnt/Jannik-Cloud-Volume-01 2>/dev/null | awk '{printf "%.1f", $1/1024/1024}')
    if [[ -n "$volume_size" ]]; then
        check_pass "Persistent volume mounted: /mnt/Jannik-Cloud-Volume-01"
    else
        check_fail "Cannot read persistent volume"
    fi
else
    check_fail "Persistent volume not found: /mnt/Jannik-Cloud-Volume-01"
fi

# Check free space
if [[ -d "/mnt/Jannik-Cloud-Volume-01" ]]; then
    free_space=$(df /mnt/Jannik-Cloud-Volume-01 | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    if (( free_space >= 100 )); then
        check_pass "Free space: ${free_space}GB (100GB+ required)"
    else
        check_fail "Free space: ${free_space}GB (minimum 100GB required)"
    fi
fi

# Network & DNS
echo ""
echo -e "${BLUE}Network & DNS:${NC}"

# Internet connectivity
if ping -c 1 8.8.8.8 &> /dev/null; then
    check_pass "Internet connectivity verified"
else
    check_fail "No internet connectivity"
fi

# DNS resolution
if nslookup orfel.de &> /dev/null; then
    target_ip=$(nslookup outline.orfel.de | grep "Address:" | tail -1 | awk '{print $2}')
    if [[ -n "$target_ip" ]]; then
        check_pass "DNS: outline.orfel.de resolves to $target_ip"
    else
        check_warn "DNS: orfel.de resolves, but wildcard may not be propagated"
    fi
else
    check_fail "DNS: Cannot resolve orfel.de (wildcard DNS not configured?)"
fi

# Port availability
echo ""
echo -e "${BLUE}Port Availability:${NC}"

if ! netstat -tuln 2>/dev/null | grep -q ":80 " && ! ss -tuln 2>/dev/null | grep -q ":80 "; then
    check_pass "Port 80 (HTTP) available"
else
    check_fail "Port 80 already in use"
fi

if ! netstat -tuln 2>/dev/null | grep -q ":443 " && ! ss -tuln 2>/dev/null | grep -q ":443 "; then
    check_pass "Port 443 (HTTPS) available"
else
    check_fail "Port 443 already in use"
fi

# No existing containers on port 3000-11100
base_port_conflict=0
for port in {3000..11100}; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        if [[ $base_port_conflict -eq 0 ]]; then
            check_warn "Some ports in service range (3000-11100) may be in use"
            base_port_conflict=1
        fi
    fi
done
if [[ $base_port_conflict -eq 0 ]]; then
    check_pass "Service ports (11000-11013) available"
fi

# Software Prerequisites
echo ""
echo -e "${BLUE}Software & Tools:${NC}"

if command -v docker &> /dev/null; then
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    check_pass "Docker installed: $docker_version"
else
    check_warn "Docker not installed (will be installed by bootstrap.sh)"
fi

if command -v age &> /dev/null; then
    check_pass "age encryption tool installed"
else
    check_warn "age not installed (will be installed by bootstrap.sh)"
fi

if command -v fail2ban-client &> /dev/null; then
    check_pass "fail2ban installed"
else
    check_warn "fail2ban not installed (will be installed by bootstrap.sh)"
fi

# AGE Key Setup
echo ""
echo -e "${BLUE}AGE Encryption Setup:${NC}"

if [[ -f "/opt/Jannik-Cloud/keys/age-key.txt" ]]; then
    if grep -q "^AGE-SECRET-KEY-" /opt/Jannik-Cloud/keys/age-key.txt; then
        check_pass "AGE private key present at /opt/Jannik-Cloud/keys/age-key.txt"
    else
        check_fail "AGE key file exists but is invalid (must start with AGE-SECRET-KEY-)"
    fi
else
    check_warn "AGE key not found (bootstrap.sh will prompt for it)"
fi

# Repository Structure
echo ""
echo -e "${BLUE}Repository Structure:${NC}"

required_dirs=(
    "infrastructure"
    "services"
    "services/caddy"
    "services/outline"
    "services/litellm"
    "services/portainer"
    "services/owncloud"
    "services/nextcloud"
    "services/mediawiki"
    "services/baserow"
    "services/vaultwarden"
    "services/librechat"
    "services/ntfy"
    "services/n8n"
    "services/gitea"
    "services/homeassistant"
    "services/stirling-pdf"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        check_pass "Directory exists: $dir"
    else
        check_fail "Missing directory: $dir"
    fi
done

# Configuration Files
echo ""
echo -e "${BLUE}Configuration Files:${NC}"

required_files=(
    "infrastructure/bootstrap.sh"
    "infrastructure/decrypt-secrets.sh"
    "services/caddy/docker-compose.yml"
    "services/caddy/Caddyfile"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        check_pass "File exists: $file"
    else
        check_fail "Missing file: $file"
    fi
done

# Summary
echo ""
echo -e "${BLUE}======================================"
echo "Summary:"
echo -e "======================================${NC}"
echo -e "✓ Passed: ${GREEN}${checks_passed}${NC}"
echo -e "✗ Failed: ${RED}${checks_failed}${NC}"

if [[ $checks_failed -gt 0 ]]; then
    echo ""
    echo -e "${RED}Deployment checklist FAILED.${NC}"
    echo "Please address the failed checks before running bootstrap.sh"
    exit 1
else
    echo ""
    echo -e "${GREEN}All checks passed!${NC}"
    echo ""
    echo "You can now run:"
    echo -e "${YELLOW}sudo infrastructure/bootstrap.sh${NC}"
    exit 0
fi
