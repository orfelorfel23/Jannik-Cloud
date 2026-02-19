# Deployment Guide

Complete step-by-step guide to deploy Jannik-Cloud infrastructure.

## Prerequisites

- Ubuntu 24 LTS server
- Root access
- Domain: orfel.de with wildcard DNS pointing to server
- Persistent volume mounted at: /mnt/Jannik-Cloud-Volume-01

## Step 1: Generate AGE Key Pair

On your **local machine** (not the server):

```bash
./scripts/generate-age-key.sh
```

This creates `age-key.txt` with your private key and displays your public key.

**Important:**
- Keep `age-key.txt` SECURE and BACKED UP
- Share the PUBLIC key with team members
- You'll need the PRIVATE key for deployment

## Step 2: Encrypt Environment Files

The repository includes plaintext .env files for demonstration. Before deploying:

```bash
# Encrypt all .env files with your AGE public key
./scripts/encrypt-all-env.sh age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Optional: Remove plaintext .env files (after verifying .env.age files exist)
find services -name '.env' ! -name '*.age' -delete
```

## Step 3: Push to Git

```bash
git add -A
git commit -m "Add encrypted environment files"
git remote add origin <your-git-repository-url>
git push -u origin main
```

## Step 4: Clone Repository on Server

SSH into your Ubuntu server:

```bash
ssh root@your-server-ip

# Clone the repository
cd /opt
git clone <your-git-repository-url> Jannik-Cloud
cd Jannik-Cloud
```

## Step 5: Deploy Everything

Run the deployment script:

```bash
sudo ./deploy_script.sh
```

The script will:
1. Install Docker, docker-compose plugin, age, fail2ban
2. Prompt for your AGE private key (paste it when asked)
3. Decrypt all .env.age files
4. Create Docker network
5. Start Caddy reverse proxy
6. Start all services

**AGE Key Prompt:**
When prompted, paste your AGE private key (from `age-key.txt`):
```
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

The key will be stored securely at `/opt/Jannik-Cloud/keys/age-key.txt` with permissions 600.

## Step 6: Verify Deployment

Check that all services are running:

```bash
./scripts/check-status.sh
```

You should see all containers running.

## Step 7: Access Services

All services are now available at:

- https://outline.orfel.de
- https://llm.orfel.de
- https://port.orfel.de
- https://owncloud.orfel.de
- https://nextcloud.orfel.de
- https://wiki.orfel.de
- https://br.orfel.de
- https://pw.orfel.de
- https://chat.orfel.de
- https://ntfy.orfel.de
- https://n8n.orfel.de
- https://git.orfel.de
- https://home.orfel.de
- https://pdf.orfel.de

HTTPS certificates are automatically obtained from Let's Encrypt.

## Step 8: Initial Service Setup

Some services require initial setup on first access:

### Portainer
- Visit https://port.orfel.de
- Create admin account
- Connect to local Docker environment

### Nextcloud
- Visit https://nextcloud.orfel.de
- Login with credentials from `/opt/Jannik-Cloud/services/nextcloud/.env`

### Gitea
- Visit https://git.orfel.de
- Complete installation wizard
- Use database credentials from `/opt/Jannik-Cloud/services/gitea/.env`

### Home Assistant
- Visit https://home.orfel.de
- Create account and configure

## Updating Services

To update a service:

```bash
cd /opt/Jannik-Cloud/services/<service-name>
docker compose pull
docker compose up -d
```

To update all services:

```bash
cd /opt/Jannik-Cloud
for dir in services/*/; do
  cd "$dir"
  docker compose pull
  docker compose up -d
  cd ../..
done
```

## Redeploying After Changes

If you make changes to the repository:

```bash
cd /opt/Jannik-Cloud
git pull
sudo ./deploy_script.sh
```

## Backup Strategy

### Critical Files to Backup

1. **AGE Private Key**: `/opt/Jannik-Cloud/keys/age-key.txt`
2. **Persistent Data**: `/mnt/Jannik-Cloud-Volume-01/`
3. **Git Repository**: Push all changes to remote

### Backup Script Example

```bash
#!/bin/bash
# Backup all service data
tar -czf jannik-cloud-backup-$(date +%Y%m%d).tar.gz \
  /mnt/Jannik-Cloud-Volume-01/ \
  /opt/Jannik-Cloud/keys/

# Upload to backup location
# rsync, rclone, or your preferred backup tool
```

## Troubleshooting

### Service won't start

```bash
cd /opt/Jannik-Cloud/services/<service-name>
docker compose logs -f
```

### Can't decrypt .env files

Verify AGE key:
```bash
cat /opt/Jannik-Cloud/keys/age-key.txt
```

Should start with `AGE-SECRET-KEY-`

### Network issues

Check Docker network:
```bash
docker network inspect jannik-cloud-net
```

Recreate if needed:
```bash
docker network rm jannik-cloud-net
docker network create jannik-cloud-net
```

### SSL certificate issues

Check Caddy logs:
```bash
cd /opt/Jannik-Cloud/caddy
docker compose logs -f
```

### Port conflicts

Only ports 80 and 443 should be exposed on the host (by Caddy).
All other services use internal Docker network.

## Security Recommendations

1. **Firewall**: Only allow ports 22, 80, 443
   ```bash
   ufw allow 22/tcp
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

2. **SSH hardening**: Disable password auth, use keys only

3. **Regular updates**:
   ```bash
   apt update && apt upgrade -y
   ```

4. **Monitor logs**: Check Caddy and service logs regularly

5. **Backup AGE key**: Store in multiple secure locations

## Disaster Recovery

If you need to rebuild from scratch:

1. Deploy fresh Ubuntu 24 LTS server
2. Mount persistent volume at `/mnt/Jannik-Cloud-Volume-01`
3. Clone repository to `/opt/Jannik-Cloud`
4. Run `sudo ./deploy_script.sh`
5. Provide AGE private key when prompted
6. All services will start with existing data

## Support

- **Email**: jannik.mueller.jannik+git@googlemail.com
- **Domain**: orfel.de
