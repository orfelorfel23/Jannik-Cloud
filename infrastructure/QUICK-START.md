# Jannik Cloud Infrastructure - Quick Start Guide

## 30-Second Setup

```bash
# 1. Clone repo
git clone <your-repo> && cd jannik-cloud-infra

# 2. Check requirements
sudo infrastructure/pre-deployment-check.sh

# 3. Deploy everything
sudo infrastructure/bootstrap.sh

# 4. Verify
docker ps | grep -c "Up"  # Should show 15+
```

## 5-Minute Deployment

### Step 1: Prerequisites
- [ ] Ubuntu 24 LTS server running
- [ ] Domain orfel.de with wildcard DNS (*.orfel.de)
- [ ] Persistent volume mounted at `/mnt/Jannik-Cloud-Volume-01`
- [ ] Ports 80, 443 open to internet
- [ ] root or sudo access

### Step 2: Clone Repository
```bash
git clone https://github.com/yourusername/jannik-cloud-infra.git
cd jannik-cloud-infra
```

### Step 3: Run Pre-Deployment Check
```bash
sudo infrastructure/pre-deployment-check.sh
```

Fix any issues shown before proceeding.

### Step 4: Prepare AGE Key
```bash
# Option A: Let bootstrap.sh ask for it
# (Just run bootstrap.sh and paste key when prompted)

# Option B: Pre-place the key
echo "Your AGE-SECRET-KEY-..." | sudo tee /opt/Jannik-Cloud/keys/age-key.txt
sudo chmod 600 /opt/Jannik-Cloud/keys/age-key.txt
```

### Step 5: Deploy
```bash
sudo infrastructure/bootstrap.sh
```

Expected output:
```
[SUCCESS] Docker installed
[SUCCESS] Docker network created
[SUCCESS] Caddy started
[SUCCESS] 14 services started
[SUCCESS] Bootstrap Complete!
```

### Step 6: Verify Services
```bash
docker ps
```

Should show 15+ containers running.

## First Access

### 1. Open Dashboard
- Browse to: **https://outline.orfel.de** (or any service)
- SSL certificate auto-purchased (Let's Encrypt)
- May take 2-5 minutes for initial HTTPS setup

### 2. Service Access

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Outline | outline.orfel.de | username: Jannik, check .env |
| Gitea | git.orfel.de | Create on first run |
| NextCloud | nextcloud.orfel.de | username: Jannik |
| Portainer | port.orfel.de | admin, check .env |
| Vaultwarden | pw.orfel.de | Create on first run |

### 3. View Service Passwords
```bash
grep "PASSWORD" services/outline/.env
grep "PASSWORD" services/*/env
```

## Common Operations

### Check Status
```bash
# All services
docker ps

# Specific service
docker logs outline

# Follow logs in real-time
docker logs -f outline
```

### Restart Services
```bash
# Single service
cd services/outline && docker compose restart

# All services
for d in services/*/; do (cd "$d" && docker compose restart); done
```

### Update Services
```bash
# All services
for d in services/*/; do (cd "$d" && docker compose pull && docker compose up -d); done
```

### Stop Everything
```bash
# All services
for d in services/*/; do (cd "$d" && docker compose down); done
```

## Useful Commands

```bash
# View all .env files
find services -name ".env" -exec grep "PASSWORD" {} + | head -20

# Check disk usage
du -sh /mnt/Jannik-Cloud-Volume-01/*

# Monitor resource usage
docker stats

# View network
docker network inspect jannik-cloud-net

# Execute command in container
docker exec gitea sh -c "whoami"

# Database backup
docker exec outline-postgres pg_dump -U outline_user outline > outline-backup.sql

# Docker cleanup
docker system prune -a
```

## Troubleshooting

### Services won't start
```bash
# Check docker status
sudo systemctl status docker

# View error logs
docker logs <service-name>

# Validate compose file
docker compose -f services/<service>/docker-compose.yml config
```

### HTTPS not working
```bash
# Check Caddy
docker logs caddy

# Verify DNS
nslookup outline.orfel.de

# Test certificate
curl -v https://outline.orfel.de
```

### No database connections
```bash
# Check PostgreSQL
docker logs <service>-postgres

# Test connection
docker exec <service>-postgres psql -U <user> -d <database> -c "SELECT 1;"
```

### Out of storage
```bash
# See what's taking space
du -sh /mnt/Jannik-Cloud-Volume-01/* | sort -h

# Clean up old containers
docker container prune -f

# Clean up images
docker image prune -a
```

## Get Help

### View Service Documentation
```bash
cat services/outline/README.md
cat services/nextcloud/README.md
cat services/gitea/README.md
```

### Check Logs
```bash
# Last 50 lines
docker logs -n 50 <service-name>

# Last 5 minutes
docker logs --since 5m <service-name>

# Follow in real-time
docker logs -f <service-name> | head -100
```

### Test API
```bash
# Caddy health
curl https://orfel.de/health

# Ntfy test
curl -X POST https://ntfy.orfel.de/test -d "Test message"

# Check certificate
curl -I https://outline.orfel.de
```

## Next Steps

1. **Configure Services**
   - Set up user accounts
   - Configure integrations
   - Customize settings

2. **Add Data**
   - Upload files to NextCloud
   - Create repos in Gitea
   - Build workflows in N8N

3. **Set Up Backups**
   - Database backups
   - Volume snapshots
   - Encrypted backups

4. **Monitor & Alert**
   - Set up ntfy notifications
   - Configure monitoring
   - Create alerting rules

## Support

- **Docs**: See individual service README.md files
- **Logs**: `docker logs <service-name>`
- **Status**: `docker ps`
- **Health**: `curl https://orfel.de`

## Quick Links

- Outline: https://docs.getoutline.com/
- NextCloud: https://docs.nextcloud.com/
- Gitea: https://docs.gitea.io/
- N8N: https://docs.n8n.io/
- Docker: https://docs.docker.com/
