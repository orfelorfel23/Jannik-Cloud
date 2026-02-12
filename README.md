# Jannik Cloud Infrastructure

A production-ready, self-hosted infrastructure featuring 15 containerized services deployed on Hetzner Ubuntu 24 LTS via Docker Compose.

## Quick Start

```bash
git clone <your-repo>
cd <repo-directory>
sudo infrastructure/bootstrap.sh
```

The bootstrap script automates everything:
- Installs Docker, Docker Compose, age encryption, and fail2ban
- Manages AGE secret keys for encryption
- Decrypts all service configurations (.env.age → .env)
- Creates the shared Docker network
- Deploys all services in the correct order

## Infrastructure Overview

```
┌─────────────────────────────────────────────────────┐
│                  Caddy Reverse Proxy                 │
│            (Port 80, 443 - Public Internet)          │
└────┬──────────────────────────────────────────────┬──┘
     │                                              │
     ▼                                              ▼
┌─────────────────────────────────────────────────────┐
│         jannik-cloud-net (Docker Network)            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────┬──────────┬──────────┬──────────┐   │
│  │ Outline  │ LiteLLM  │Portainer │OwnCloud  │   │
│  │ :11000   │  :11001  │ :11002   │ :11003   │   │
│  └──────────┴──────────┴──────────┴──────────┘   │
│                                                     │
│  ┌──────────┬──────────┬──────────┬──────────┐   │
│  │NextCloud │MediaWiki │ Baserow  │Vault-    │   │
│  │ :11004   │  :11005  │ :11006   │ warden   │   │
│  │          │          │          │ :11007   │   │
│  └──────────┴──────────┴──────────┴──────────┘   │
│                                                     │
│  ┌──────────┬──────────┬──────────┬──────────┐   │
│  │LibreChat │   Ntfy   │   N8N    │  Gitea   │   │
│  │ :11008   │  :11009  │ :11010   │ :11011   │   │
│  └──────────┴──────────┴──────────┴──────────┘   │
│                                                     │
│  ┌──────────┬──────────┐                         │
│  │HomeAssist│Stirling  │                         │
│  │ant:11012 │PDF:11013 │                         │
│  └──────────┴──────────┘                         │
│                                                     │
└─────────────────────────────────────────────────────┘
         │
         └── /mnt/Jannik-Cloud-Volume-01
             Persistent Data Storage
```

## Services & URLs

| Service | Domain | Port | Purpose |
|---------|--------|------|---------|
| **Caddy** | orfel.de | 80, 443 | Reverse proxy & SSL/TLS |
| **Outline** | outline.orfel.de | 11000 | Team knowledge base |
| **LiteLLM** | llm.orfel.de | 11001 | LLM API gateway |
| **Portainer** | port.orfel.de | 11002 | Docker management UI |
| **OwnCloud** | owncloud.orfel.de | 11003 | File sync & sharing |
| **NextCloud** | nextcloud.orfel.de | 11004 | File hosting & collaboration |
| **MediaWiki** | wiki.orfel.de | 11005 | Wiki platform |
| **Baserow** | br.orfel.de | 11006 | Database & no-code platform |
| **Vaultwarden** | pw.orfel.de | 11007 | Password manager |
| **LibreChat** | chat.orfel.de | 11008 | Multi-LLM chat interface |
| **Ntfy** | ntfy.orfel.de | 11009 | Push notifications |
| **N8N** | n8n.orfel.de | 11010 | Workflow automation |
| **Gitea** | git.orfel.de | 11011 | Git service |
| **HomeAssistant** | home.orfel.de | 11012 | Home automation |
| **Stirling PDF** | pdf.orfel.de | 11013 | PDF tools |

## Directory Structure

```
.
├── infrastructure/
│   ├── bootstrap.sh           # Main deployment script
│   └── decrypt-secrets.sh     # Manual secret decryption
├── services/
│   ├── caddy/
│   │   ├── docker-compose.yml
│   │   ├── Caddyfile          # Reverse proxy config
│   │   ├── .env               # Configuration
│   │   ├── .env.age           # Encrypted backup
│   │   ├── generate-env.sh    # Env generator
│   │   └── README.md
│   ├── outline/
│   ├── litellm/
│   ├── portainer/
│   ├── owncloud/
│   ├── nextcloud/
│   ├── mediawiki/
│   ├── baserow/
│   ├── vaultwarden/
│   ├── librechat/
│   ├── ntfy/
│   ├── n8n/
│   ├── gitea/
│   ├── homeassistant/
│   └── stirling-pdf/
├── README.md                  # This file
└── .gitignore                 # Git ignore rules
```

Each service folder contains:
- `docker-compose.yml` - Container definition
- `.env` - Plain-text configuration (local only)
- `.env.age` - Encrypted backup
- `generate-env.sh` - Script to generate .env with secure passwords
- `README.md` - Service-specific documentation

## System Requirements

- **OS**: Ubuntu 24 LTS
- **Ram**: 4GB minimum (8GB+ recommended for all services)
- **Storage**: 100GB+ (depends on usage)
- **Network**: Internet with stable DNS
- **Ports**: 80, 443 open to internet
- **Domain**: DNS configured (wildcard or individual records)
- **Persistent Volume**: /mnt/Jannik-Cloud-Volume-01

## Prerequisites

1. **Domain Name**: orfel.de with wildcard DNS
   - DNS Records: *.orfel.de → server IP

2. **Hetzner Volume**: Mounted at `/mnt/Jannik-Cloud-Volume-01`
   ```bash
   mount | grep Jannik-Cloud-Volume-01
   ```

3. **AGE Encryption Key**: For secret management
   Generate one if you don't have:
   ```bash
   age-keygen -o
   ```

## Installation Steps

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/jannik-cloud-infra.git
cd jannik-cloud-infra
```

### 2. Run Bootstrap
```bash
sudo infrastructure/bootstrap.sh
```

The script will:
- Prompt for AGE private key (if not found at `/opt/Jannik-Cloud/keys/age-key.txt`)
- Install Docker and dependencies
- Create shared Docker network
- Decrypt all .env.age files
- Start Caddy first, then all other services

### 3. Verify Deployment
```bash
docker ps
docker logs caddy
```

## Usage & Management

### View Service Logs
```bash
docker logs <service-name>

# Follow logs in real-time
docker logs -f <service-name>

# View multiple services
docker compose -f services/caddy/docker-compose.yml logs
```

### Restart a Service
```bash
cd services/<service-name>
docker compose restart
```

### Stop All Services
```bash
for service in services/*/; do
  cd "$service"
  docker compose down
  cd - > /dev/null
done
```

### Access Service Shell
```bash
# E.g., PostgreSQL for Outline
docker exec -it outline-postgres psql -U outline_user -d outline
```

## Security Considerations

### 1. Secret Management (AGE Encryption)

All sensitive data is encrypted with AGE:
```bash
# Encrypt a file
age -R /path/to/age-key.pub < sensitive-file > sensitive-file.age

# Decrypt a file
age -d -i /opt/Jannik-Cloud/keys/age-key.txt < sensitive-file.age > sensitive-file
```

### 2. File Permissions

Secrets are protected with proper permissions:
```bash
# .env files: rw only for root
chmod 600 services/*/.env

# Age key: read-write only for root
chmod 600 /opt/Jannik-Cloud/keys/age-key.txt
```

### 3. Network Isolation

- Only Caddy exposes ports 80/443 to the internet
- Services communicate via internal Docker network (jannik-cloud-net)
- No direct internet access to individual services

### 4. Firewall Rules with fail2ban

fail2ban is installed and running:
```bash
# Check fail2ban status
fail2ban-client status

# View SSH protection
fail2ban-client status sshd
```

### 5. HTTPS/TLS Certificates

- Automatic HTTPS via Let's Encrypt
- Caddy handles all certificate management
- Certificates stored in Caddy container volumes

## Backup & Recovery

### Backup Strategy

1. **Database Backups**
```bash
# Backup Outline
docker exec outline-postgres pg_dump -U outline_user outline > outline-backup.sql

# Backup all PostgreSQL databases
for service in nextcloud mediawiki gitea n8n; do
  docker exec ${service}-postgres pg_dump -U ${service}_user ${service} > ${service}-backup.sql
done
```

2. **Volume Backups**
```bash
# Backup persistent volumes
rsync -av /mnt/Jannik-Cloud-Volume-01/ /backup/jannik-cloud/
```

3. **Configuration Backups**
```bash
# Backup encrypted configurations
tar -czf services-backups.tar.gz services/*/.env.age
```

### Recovery

```bash
# Restore database
docker exec -i outline-postgres psql -U outline_user outline < outline-backup.sql

# Restore volumes
rsync -av /backup/jannik-cloud/ /mnt/Jannik-Cloud-Volume-01/
```

## Updating Services

### Update All Services
```bash
# Pull latest images (no rebuild needed)
for service in services/*/; do
  cd "$service"
  docker compose pull
  docker compose up -d
  cd - > /dev/null
done
```

### Update Specific Service
```bash
cd services/<service-name>
docker compose pull
docker compose up -d
```

## Monitoring & Maintenance

### Check Service Status
```bash
# All containers
docker ps -a

# Service-specific
docker compose -f services/caddy/docker-compose.yml ps
```

### Monitor Resource Usage
```bash
# Real-time resource monitoring
docker stats

# Disk usage
du -sh /mnt/Jannik-Cloud-Volume-01/*
```

### Clean Up Docker Resources
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

## Environment Configuration

Each service has its own `.env` file with required variables:

### Standard Variables
```
USERNAME=Jannik
EMAIL=jannik.mueller.jannik+git@googlemail.com
```

### Service-Specific Variables
- `DB_USER`, `DB_PASSWORD` - Database credentials
- `ADMIN_PASSWORD` - Admin account password
- `API_KEY`, `SECRET_KEY` - Integration keys
- Service-specific settings (timeouts, features, etc.)

### Generate New .env Files
```bash
cd services/<service-name>
bash generate-env.sh
```

This creates a new `.env` with randomly generated secure passwords.

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker logs <service-name>

# Check docker-compose validity
docker compose -f services/<service-name>/docker-compose.yml config

# Check network connectivity
docker network inspect jannik-cloud-net
```

### Database Connection Failed
```bash
# Verify PostgreSQL is running
docker ps | grep postgres

# Check logs
docker logs <service>-postgres

# Test connection
docker exec <service>-postgres psql -U <user> -d <database> -c "SELECT 1;"
```

### HTTPS Certificate Issues
```bash
# Check Caddy logs
docker logs caddy

# Verify domain DNS
nslookup outline.orfel.de

# Check Let's Encrypt rate limits
curl https://api.letsencrypt.org/acme/new-nonce -I
```

### Out of Storage
```bash
# Check volume usage
du -sh /mnt/Jannik-Cloud-Volume-01/*

# Clean up old containers
docker container prune

# Clean up old images
docker image prune -a

# Reduce database sizes if possible (archiving)
```

## API Examples

### Ntfy - Send Notification
```bash
curl -X POST https://ntfy.orfel.de/my-topic \
  -H "Title: Deployment Complete" \
  -d "All services are running"
```

### N8N - Create Workflow via API
```bash
curl -X POST https://n8n.orfel.de/api/v1/workflows \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Workflow"}'
```

### Gitea - Clone Repository
```bash
git clone https://git.orfel.de/username/repo-name.git
cd repo-name
```

## Performance Tuning

### Docker Compose Configuration
Services use optimized settings:
- Health checks enabled (30s interval)
- Proper restart policies
- Resource limits (if needed)

### Database Optimization
- PostgreSQL configured for typical workloads
- Indexes created automatically
- Connection pooling enabled

### Cache Services
- Redis used for caching (NextCloud, Outline, etc.)
- Reduces database load
- Improves response times

## Advanced Configuration

### Custom Caddy Rules
Edit `services/caddy/Caddyfile` to add routes:
```
myservice.orfel.de {
  reverse_proxy myservice:8080
}
```

Then restart Caddy:
```bash
cd services/caddy && docker compose restart
```

### Custom Environment Variables
Edit `.env` file in service directory and restart:
```bash
cd services/<service> && docker compose restart
```

### Add New Service
1. Create directory: `mkdir services/newservice`
2. Create files: `docker-compose.yml`, `.env`, `generate-env.sh`, `README.md`
3. Update `services/caddy/Caddyfile`
4. Deploy:
   ```bash
   cd services/newservice
   docker compose up -d
   ```

## Support & Documentation

### Service-Specific Documentation
See `services/<service-name>/README.md` for detailed service info.

### Links
- Caddy: https://caddyserver.com/docs/
- Docker: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- Age Encryption: https://age-encryption.org/
- Ubuntu 24 LTS: https://ubuntu.com/

## License

This infrastructure setup is provided as-is. Ensure compliance with individual service licenses.

## Contact

- **Email**: jannik.mueller.jannik+git@googlemail.com
- **Domain**: orfel.de

## Version History

- **v1.0** (Feb 2026): Initial production-ready deployment with 15 services
