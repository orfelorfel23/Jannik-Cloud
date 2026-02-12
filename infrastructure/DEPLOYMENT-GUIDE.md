# Jannik Cloud Infrastructure - Complete Deployment Guide

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Installation Steps](#installation-steps)
5. [Verification](#verification)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Service Management](#service-management)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Backup & Recovery](#backup--recovery)
10. [Troubleshooting](#troubleshooting)

## Overview

This infrastructure deploys 15 containerized services on a single Hetzner Ubuntu 24 LTS server with:

- **Caddy** reverse proxy with automatic HTTPS
- **Shared Docker network** (jannik-cloud-net)
- **Persistent volume** on /mnt/Jannik-Cloud-Volume-01
- **AGE encryption** for secrets management
- **Docker Compose** for service orchestration

Services include: Outline, LiteLLM, Portainer, OwnCloud, NextCloud, MediaWiki, Baserow, Vaultwarden, LibreChat, Ntfy, N8N, Gitea, HomeAssistant, and Stirling PDF.

## System Requirements

### Hardware Minimum
- **RAM**: 4GB (8GB+ recommended for all services)
- **Storage**: 100GB+ persistent volume
- **CPU**: Modern multi-core processor
- **Network**: Stable internet connection

### Software Prerequisites
- **OS**: Ubuntu 24 LTS (tested)
- **Docker**: Installed and running
- **Sudo access**: Required for bootstrap
- **curl/wget**: For downloading installation files

### Network Requirements
- **Ports 80 & 443**: Open to internet (for public services)
- **Domain**: orfel.de with wildcard DNS (*.orfel.de)
- **DNS Resolution**: 
  - `outline.orfel.de` → server IP
  - `*.orfel.de` → server IP (wildcard)

### Storage Requirements
- **Persistent Volume**: `/mnt/Jannik-Cloud-Volume-01` (100GB+)
  - Pre-mounted and formatted
  - Read/write permissions for Docker

## Pre-Deployment Checklist

Run the automated checklist:
```bash
sudo infrastructure/pre-deployment-check.sh
```

Manual verification:
```bash
# Check OS
cat /etc/os-release | grep "PRETTY_NAME"

# Check available RAM
free -h

# Check root access
id

# Verify persistent volume
df -h /mnt/Jannik-Cloud-Volume-01

# Check ports availability
ss -tlnp | grep -E ":(80|443)"

# Verify DNS
nslookup outline.orfel.de

# Check internet
ping -c 1 8.8.8.8
```

## Installation Steps

### 1. Clone Repository
```bash
# Clone the repository
git clone <your-repo-url> jannik-cloud
cd jannik-cloud

# Verify structure
ls -la
# Should show: infrastructure/, services/, README.md, etc.
```

### 2. Prepare AGE Keys

AGE keys encrypt sensitive .env files. Choose one method:

**Method A: Interactive (Recommended)**
- bootstrap.sh will prompt you to paste your AGE secret key
- Input is hidden (secure)

**Method B: Pre-Place Key**
```bash
# Create keys directory
sudo mkdir -p /opt/Jannik-Cloud/keys
sudo chmod 700 /opt/Jannik-Cloud/keys

# Place your AGE secret key (replace with your actual key)
echo "AGE-SECRET-KEY-1234567890abcdefghijklmnopqrstuvwxyz1234567" | \
  sudo tee /opt/Jannik-Cloud/keys/age-key.txt > /dev/null

# Set permissions (read/write for root only)
sudo chmod 600 /opt/Jannik-Cloud/keys/age-key.txt

# Verify
sudo cat /opt/Jannik-Cloud/keys/age-key.txt | head -c 20
# Should show: AGE-SECRET-KEY-
```

See `infrastructure/AGE-SETUP.md` for key generation.

### 3. Pre-Deployment Checks
```bash
# Run automated checks
sudo infrastructure/pre-deployment-check.sh

# Expected output:
# ✓ Ubuntu OS detected
# ✓ Running as root
# ✓ RAM: 8.0GB (4GB+ required)
# ✓ Persistent volume mounted
# ... (no failures)
```

### 4. Execute Bootstrap
```bash
# Make scripts executable
chmod +x infrastructure/*.sh

# Run bootstrap
sudo infrastructure/bootstrap.sh

# Will take 5-15 minutes depending on internet speed
```

### 5. Monitor Bootstrap Progress
```bash
# In another terminal, watch container startup
watch -n 2 'docker ps | wc -l'

# Or follow bootstrap logs
tail -f /var/log/syslog | grep -i docker
```

## Verification

### Verify All Services Running
```bash
# Check containers
docker ps | wc -l
# Should show 16+ containers (15 services + dependencies)

# List all services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Expected services:
# caddy           Up 2 minutes
# outline         Up 2 minutes
# litellm         Up 2 minutes
# portainer       Up 2 minutes
# ... (14 total)
```

### Test Service Access
```bash
# Test Caddy reverse proxy
curl -I https://outline.orfel.de

# Test health endpoints
curl https://orfel.de/health

# Test HTTPS certificate
openssl s_client -connect outline.orfel.de:443 -brief

# Expected: Certificate should be from Let's Encrypt
```

### Verify Docker Network
```bash
# Check network exists
docker network inspect jannik-cloud-net

# Check services connected
docker network inspect jannik-cloud-net | grep -A 50 "Containers"
```

### Check Persistent Volume
```bash
# Verify mount point
df -h /mnt/Jannik-Cloud-Volume-01

# Check service directories
ls -la /mnt/Jannik-Cloud-Volume-01/

# Expected directories:
# caddy, outline, litellm, portainer, owncloud, ...
```

## Post-Deployment Configuration

### 1. Initial Service Setup

#### Outline (Knowledge Base)
```bash
# Navigate to https://outline.orfel.de
# Create account for Jannik
# Configure OIDC (optional)
```

#### Portainer (Docker UI)
```bash
# Navigate to https://port.orfel.de
# Create admin account
# Connect to local Docker socket
```

#### Gitea (Git Service)
```bash
# Navigate to https://git.orfel.de
# Gitea shows initial setup wizard
# Create admin account
# Configure SSH access
```

#### NextCloud (File Hosting)
```bash
# Navigate to https://nextcloud.orfel.de
# Admin account created with Jannik/password from .env
# Configure additional users
# Set up sync clients
```

### 2. Configure Backups
```bash
# Backup all data
sudo infrastructure/backup.sh /backup

# Schedule daily backups
sudo crontab -e
# Add: 0 2 * * * /path/to/infrastructure/backup.sh /backup
```

### 3. Set Up Monitoring
```bash
# Create ntfy topic for alerts
curl -X POST https://ntfy.orfel.de/jannik-cloud-alerts \
  -d "Infrastructure monitoring enabled"

# Subscribe in mobile app or browser
```

### 4. Configure Additional Users
```bash
# Each service supports individual user creation
# See respective service README for details

# Examples:
# NextCloud: Admin panel → Users
# Gitea: Registration or admin create
# OwnCloud: Admin panel → Users
```

## Service Management

### Start/Stop Services
```bash
# Start all services
sudo infrastructure/service-manager.sh start

# Stop specific service
sudo infrastructure/service-manager.sh stop gitea

# Restart all
sudo infrastructure/service-manager.sh restart

# View status
sudo infrastructure/service-manager.sh status
```

### View Logs
```bash
# Last 50 lines
docker logs -n 50 outline

# Follow in real-time
docker logs -f outline

# Last 5 minutes with timestamps
docker logs -f --since 5m outline

# All services
sudo infrastructure/service-manager.sh logs
```

### Update Services
```bash
# Update all services
for dir in services/*/; do
  cd "$dir"
  docker compose pull
  docker compose up -d
  cd - > /dev/null
done

# Or use the manager
sudo infrastructure/service-manager.sh recreate
```

### Access Service Containers
```bash
# Execute command in container
docker exec outline sh -c "whoami"

# Open shell in container
docker exec -it outline /bin/sh

# Access databases
docker exec -it outline-postgres psql -U outline_user -d outline
```

## Monitoring & Maintenance

### Health Checks
```bash
# Service health status
docker ps --format "{{.Names}}\t{{.Status}}"

# Health check logs
docker inspect --format='{{json .State.Health}}' outline

# Network connectivity
docker exec outline ping -c 1 outline-postgres
```

### Disk Usage
```bash
# Space used by services
du -sh /mnt/Jannik-Cloud-Volume-01/*

# Container sizes
docker ps --format "table {{.Names}}\t{{.Size}}"

# Image sizes
docker images --format "table {{.Repository}}\t{{.Size}}"
```

### Resource Usage
```bash
# Real-time statistics
docker stats

# Historical usage
docker stats --no-stream

# Memory usage by service
docker stats --format "table {{.Container}}\t{{.MemUsage}}"
```

### Log Management
```bash
# Check log driver
docker inspect outline | grep -A 5 LogDriver

# Rotate logs
docker logs outline > /backup/outline-logs-$(date +%Y%m%d).txt

# Clean old logs
docker logs --tail 1000 outline > /tmp/recent.log && \
  docker logs --tail 1000 outline > ~/.docker/latest.log
```

## Backup & Recovery

### Automated Backup
```bash
# Backup everything
sudo infrastructure/backup.sh /backup

# Creates: jannik-cloud-backup-<timestamp>/
#   - jannik-cloud-volume.tar.gz (100GB+)
#   - services-config.tar.gz
#   - services-secrets.tar.gz
```

### Database Backups
```bash
# Backup single database
docker exec outline-postgres pg_dump -U outline_user outline \
  > /backup/outline-$(date +%Y%m%d).sql

# Backup all PostgreSQL services
for svc in outline nextcloud gitea n8n mediawiki baserow; do
  docker exec ${svc}-postgres pg_dump \
    -U ${svc}_user ${svc} \
    > /backup/${svc}-$(date +%Y%m%d).sql
done
```

### Restore Process
```bash
# Restore database
docker exec -i outline-postgres psql -U outline_user outline \
  < /backup/outline-backup.sql

# Restore volume
tar -xzf /backup/volumes.tar.gz -C /mnt/

# Restart service
docker compose -f services/outline/docker-compose.yml restart
```

## Troubleshooting

### Services Won't Start
```bash
# Check Docker status
sudo systemctl status docker

# Verify docker-compose files
docker compose -f services/outline/docker-compose.yml config

# Try pulling latest images
docker compose -f services/outline/docker-compose.yml pull

# Remove orphaned containers
docker compose -f services/outline/docker-compose.yml down -v
docker compose -f services/outline/docker-compose.yml up -d
```

### HTTPS Certificate Issues
```bash
# Check Caddy logs
docker logs caddy

# Verify domain DNS
nslookup outline.orfel.de
dig outline.orfel.de

# Test Let's Encrypt
curl -I https://outline.orfel.de -v

# Rate limit status
curl https://crt.sh/?q=outline.orfel.de
```

### Database Connection Errors
```bash
# Check PostgreSQL
docker logs outline-postgres

# Test connection
docker exec outline-postgres \
  psql -U outline_user -d outline -c "SELECT 1;"

# Check network
docker network inspect jannik-cloud-net | grep -i postgres

# Verify credentials in .env
grep "DB_PASSWORD" services/outline/.env
```

### Memory/Disk Issues
```bash
# Disk usage
df -h /mnt/Jannik-Cloud-Volume-01

# Clean up
docker system prune -a --volumes

# Find large files
find /mnt/Jannik-Cloud-Volume-01 -type f -size +1G

# Compress old data
tar -czf /backup/old-data.tar.gz /mnt/old-data/
rm -rf /mnt/old-data
```

### Network Connectivity
```bash
# Check container network
docker exec outline ping outline-postgres

# Check external access
docker exec outline curl -I https://google.com

# DNS resolution
docker exec outline nslookup orfel.de

# Port connectivity
docker exec outline telnet outline-postgres 5432
```

## Useful Commands Reference

```bash
# View all configuration
for svc in services/*/; do
  echo "=== $(basename $svc) ===" 
  cat "$svc/.env"
done

# Export configuration
docker compose -f services/outline/docker-compose.yml config > full-config.yml

# Backup AGE key
sudo cp /opt/Jannik-Cloud/keys/age-key.txt /backup/age-key.txt.bak
sudo chmod 600 /backup/age-key.txt.bak

# List all Docker volumes
docker volume ls

# Check Caddy state
docker exec caddy caddy list-modules

# Monitor in real-time
watch -n 2 'docker ps --format "{{.Names}}\t{{.Status}}" && echo && du -sh /mnt/Jannik-Cloud-Volume-01'
```

## Next Steps

1. **Configure Users**: Set up accounts in each service
2. **Enable Integrations**: Connect services (N8N, webhooks, etc.)
3. **Set Up Monitoring**: ntfy alerts, log aggregation
4. **Configure Backups**: Automated daily backups to external storage
5. **Document Customizations**: Keep notes of changes made
6. **Plan Scaling**: Consider add-on services or migrations

## Support Resources

- **Service Docs**: See individual `services/*/README.md`
- **AGE Setup**: `infrastructure/AGE-SETUP.md`
- **Quick Start**: `infrastructure/QUICK-START.md`
- **Main README**: Root `README.md`

## Version

- **Infrastructure**: v1.0
- **Services**: 15 total
- **Tested**: Ubuntu 24 LTS on Hetzner Cloud
- **Updated**: February 2026
