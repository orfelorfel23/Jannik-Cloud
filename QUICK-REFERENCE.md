# QUICK REFERENCE CARD
## Jannik Cloud Infrastructure - Command Cheatsheet

### DEPLOYMENT

```bash
# Clone and deploy (1 command)
git clone <repo> && cd jannik-cloud && sudo infrastructure/bootstrap.sh

# Pre-flight check
sudo infrastructure/pre-deployment-check.sh

# Manual decryption
sudo infrastructure/decrypt-secrets.sh

# Check status
docker ps | wc -l  # Should show 16+
```

### SERVICE MANAGEMENT

```bash
# View all services
docker ps
docker ps --format "table {{.Names}}\t{{.Status}}"

# Start/stop specific service
cd services/outline && docker compose up -d    # Start
cd services/outline && docker compose down      # Stop
cd services/outline && docker compose restart   # Restart

# View logs
docker logs outline                             # Last 100 lines
docker logs -f outline                          # Follow
docker logs --since 5m outline                  # Last 5 minutes

# Services manager (batch operations)
sudo infrastructure/service-manager.sh status   # All services
sudo infrastructure/service-manager.sh restart  # Restart all
sudo infrastructure/service-manager.sh logs outline
```

### ACCESS SERVICES

```
https://outline.orfel.de          (Outline)
https://llm.orfel.de              (LiteLLM)
https://port.orfel.de             (Portainer)
https://owncloud.orfel.de         (OwnCloud)
https://nextcloud.orfel.de        (NextCloud)
https://wiki.orfel.de             (MediaWiki)
https://br.orfel.de               (Baserow)
https://pw.orfel.de               (Vaultwarden)
https://chat.orfel.de             (LibreChat)
https://ntfy.orfel.de             (Ntfy)
https://n8n.orfel.de              (N8N)
https://git.orfel.de              (Gitea)
https://home.orfel.de             (HomeAssistant)
https://pdf.orfel.de              (Stirling PDF)
```

### TROUBLESHOOTING

```bash
# Check service status
docker ps | grep outline

# View error logs
docker logs outline

# Test connectivity
docker exec outline ping outline-postgres

# Access database
docker exec -it outline-postgres psql -U outline_user -d outline

# Check network
docker network inspect jannik-cloud-net

# Validate configuration
docker compose -f services/outline/docker-compose.yml config

# Disk usage
du -sh /mnt/Jannik-Cloud-Volume-01/*

# System resources
docker stats
```

### BACKUPS

```bash
# Full backup
sudo infrastructure/backup.sh /backup

# Database backup
docker exec outline-postgres pg_dump -U outline_user outline > backup.sql

# Volume backup
rsync -av /mnt/Jannik-Cloud-Volume-01/ /backup/jannik-cloud/
```

### PASSWORDS & CONFIGURATION

```bash
# View all passwords
grep "PASSWORD" services/*/.env

# View specific service config
cat services/outline/.env

# Edit configuration (requires restart)
nano services/outline/.env
cd services/outline && docker compose restart
```

### AGE ENCRYPTION

```bash
# Check AGE key
sudo cat /opt/Jannik-Cloud/keys/age-key.txt | head -c 20

# Decrypt manually
age -d -i /opt/Jannik-Cloud/keys/age-key.txt < services/outline/.env.age

# Encrypt file
age -R <pubkey> < plaintext > plaintext.age
```

### DOCKER CLEANUP

```bash
docker system prune                 # Clean up unused resources
docker system prune -a --volumes    # Full cleanup
docker container prune -f           # Remove unused containers
docker image prune -a               # Remove unused images
docker volume prune                 # Remove unused volumes
```

### NETWORK DIAGNOSTICS

```bash
# Check Docker network
docker network ls
docker network inspect jannik-cloud-net

# DNS resolution
docker exec outline nslookup orfel.de

# Port connectivity
docker exec outline telnet outline-postgres 5432

# External connectivity
docker exec outline curl -I https://google.com
```

### MONITORING

```bash
# Real-time stats
docker stats

# Container resource usage
docker stats --no-stream

# Memory usage
docker stats --format "table {{.Container}}\t{{.MemUsage}}"

# Monitor with watch
watch -n 2 'docker ps --format "{{.Names}}\t{{.Status}}"'
```

### EMERGENCY PROCEDURES

```bash
# Stop all services
for d in services/*/; do (cd "$d" && docker compose down); done

# Restart all services
for d in services/*/; do (cd "$d" && docker compose restart); done

# Check container health
docker ps --format "{{.Names}}\t{{.Status}}" | grep -v "Up"

# View full logs with errors
docker logs outline 2>&1 | grep -i "error"

# Recreate database
cd services/outline && docker compose down -v && docker compose up -d
```

### USEFUL ONLINERS

```bash
# Restart service after config change
cd services/outline && docker compose restart

# Check all service health
docker ps --format "{{.Names}}\t{{.Status}}" | grep -c "Up"

# Total storage used
du -sh /mnt/Jannik-Cloud-Volume-01/ && du -sh /opt/Jannik-Cloud/

# Active network connections
docker exec -it outline netstat -tuln

# Environment variables in container
docker exec outline env | grep -i password

# Find large files
find /mnt/Jannik-Cloud-Volume-01 -type f -size +100M

# Service startup order
docker logs caddy --tail=5
for svc in outline litellm portainer; do echo "=== $svc ==="; docker logs $svc --tail=2; done
```

### DEBUG TEMPLATES

```bash
# Failing service debug
docker logs <service>
docker compose -f services/<service>/docker-compose.yml config
docker exec <service> env | grep DB_
docker exec <db>-postgres psql -l

# Network issues
docker network inspect jannik-cloud-net | grep -i <service>
docker exec <service> nslookup <hostname>
docker exec <service> curl -v https://google.com

# Permission issues
ls -la /mnt/Jannik-Cloud-Volume-01/<service>
docker exec <service> whoami
docker logs <service> | grep -i "permission"
```

---

**For complete documentation, see:**
- Root: `README.md`
- Quick start: `infrastructure/QUICK-START.md`
- Full guide: `infrastructure/DEPLOYMENT-GUIDE.md`
- Encryption setup: `infrastructure/AGE-SETUP.md`
- Service docs: `services/<service>/README.md`
