# Jannik-Cloud

Production-ready Docker services infrastructure for Hetzner Ubuntu 24 LTS server.

## 🚀 Quick Start

Deploy everything with a single command:

```bash
sudo ./deploy_script.sh
```

The script will:
- Install Docker, docker-compose, age, and fail2ban if needed
- Prompt for AGE private key (on first run)
- Decrypt all environment files
- Create Docker network
- Start Caddy reverse proxy
- Start all services

## 📋 Services

| Service | URL | Internal Port | Description |
|---------|-----|---------------|-------------|
| Outline | https://outline.orfel.de | 3000 | Wiki and knowledge base |
| LiteLLM | https://llm.orfel.de | 4000 | LLM proxy server |
| Portainer | https://port.orfel.de | 9000 | Docker management UI |
| ownCloud | https://owncloud.orfel.de | 8080 | File sync and share |
| Nextcloud | https://nextcloud.orfel.de | 80 | Productivity platform |
| MediaWiki | https://wiki.orfel.de | 80 | Wiki software |
| Baserow | https://br.orfel.de | 80 | No-code database |
| Vaultwarden | https://pw.orfel.de | 80 | Password manager |
| LibreChat | https://chat.orfel.de | 3080 | ChatGPT alternative |
| ntfy | https://ntfy.orfel.de | 80 | Notification service |
| n8n | https://n8n.orfel.de | 5678 | Workflow automation |
| Gitea | https://git.orfel.de | 3000 | Git service |
| Home Assistant | https://home.orfel.de | 8123 | Home automation |
| Stirling PDF | https://pdf.orfel.de | 8080 | PDF tools |

## 🏗️ Infrastructure

### Server Details
- **OS**: Ubuntu 24 LTS
- **Domain**: orfel.de (with wildcard DNS)
- **Persistent Volume**: /mnt/Jannik-Cloud-Volume-01
- **Docker Network**: jannik-cloud-net

### Reverse Proxy
Caddy handles:
- Automatic HTTPS (Let's Encrypt)
- SSL certificate management
- Reverse proxy for all services

Only Caddy exposes ports 80/443 to the host. All other services use internal Docker network ports.

## 🔐 Security

### AGE Encryption
All `.env` files containing secrets are encrypted with AGE encryption.

**First-time setup:**
1. Generate an AGE key pair:
   ```bash
   ./scripts/generate-age-key.sh
   ```

2. Share the public key with team members (for encrypting secrets)

3. Store the private key securely (needed for deployment)

**Encrypting secrets:**
```bash
# After generating/modifying .env files:
./scripts/encrypt-all-env.sh <your-age-public-key>
```

**Decrypting secrets manually:**
```bash
./scripts/decrypt-secrets.sh /path/to/age-key.txt
```

### Passwords
All passwords are 32-character cryptographically random strings generated using OpenSSL.

### Fail2ban
SSH protection enabled automatically by deployment script.

## 📁 Directory Structure

```
Jannik-Cloud/
├── deploy_script.sh          # Main deployment script
├── README.md                 # This file
├── caddy/                    # Reverse proxy
│   ├── Caddyfile
│   └── docker-compose.yml
├── services/                 # All services
│   ├── outline/
│   │   ├── docker-compose.yml
│   │   ├── generate-env.sh
│   │   ├── .env              # Generated, not in git
│   │   ├── .env.age          # Encrypted, in git
│   │   └── README.md
│   ├── litellm/
│   ├── portainer/
│   └── ...                   # Other services
└── scripts/                  # Utility scripts
    ├── decrypt-secrets.sh
    ├── generate-age-key.sh
    ├── encrypt-all-env.sh
    └── generate-password.sh
```

## 🛠️ Manual Service Management

### Start a single service
```bash
cd services/outline
docker compose up -d
```

### Stop a service
```bash
cd services/outline
docker compose down
```

### View logs
```bash
cd services/outline
docker compose logs -f
```

### Restart a service
```bash
cd services/outline
docker compose restart
```

## 🔄 Updating Services

```bash
cd services/<service-name>
docker compose pull
docker compose up -d
```

## 📝 Adding a New Service

1. Create service directory:
   ```bash
   mkdir services/myservice
   ```

2. Create `docker-compose.yml` (without "version:" attribute)

3. Create `generate-env.sh` script:
   ```bash
   cp services/outline/generate-env.sh services/myservice/
   # Edit as needed
   ```

4. Generate environment file:
   ```bash
   cd services/myservice
   ./generate-env.sh
   ```

5. Encrypt it:
   ```bash
   ./scripts/encrypt-all-env.sh <age-public-key>
   ```

6. Add to Caddyfile:
   ```
   myservice.orfel.de {
       reverse_proxy myservice:<port>
   }
   ```

7. Redeploy:
   ```bash
   sudo ./deploy_script.sh
   ```

## 🐛 Troubleshooting

### View all running containers
```bash
docker ps
```

### Check Docker network
```bash
docker network inspect jannik-cloud-net
```

### Check Caddy logs
```bash
cd caddy
docker compose logs -f
```

### Verify AGE key
```bash
grep "^AGE-SECRET-KEY-" /opt/Jannik-Cloud/keys/age-key.txt
```

### Test service connectivity
```bash
docker exec caddy wget -O- http://<service-name>:<port>
```

## 📧 Support

- **Domain**: orfel.de
- **Email**: jannik.mueller.jannik+git@googlemail.com
- **User**: Jannik

## 📜 License

Private repository for Jannik-Cloud infrastructure.
