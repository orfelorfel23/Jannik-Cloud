# Quick Start Guide

## 🚀 Deploy Everything (First Time)

```bash
# On your server
sudo ./deploy_script.sh
```

When prompted, paste your AGE private key.

## 🔑 View All Credentials

```bash
sudo ./scripts/show-credentials.sh
```

## 📊 Check Status

```bash
./scripts/check-status.sh
```

## 🔄 Restart a Service

```bash
cd services/<service-name>
docker compose restart
```

## 📝 View Logs

```bash
cd services/<service-name>
docker compose logs -f
```

## 🛑 Stop a Service

```bash
cd services/<service-name>
docker compose down
```

## ▶️ Start a Service

```bash
cd services/<service-name>
docker compose up -d
```

## 🔄 Update a Service

```bash
cd services/<service-name>
docker compose pull
docker compose up -d
```

## 🌐 Service URLs

| Service | URL |
|---------|-----|
| Outline | https://outline.orfel.de |
| LiteLLM | https://llm.orfel.de |
| Portainer | https://port.orfel.de |
| ownCloud | https://owncloud.orfel.de |
| Nextcloud | https://nextcloud.orfel.de |
| MediaWiki | https://wiki.orfel.de |
| Baserow | https://br.orfel.de |
| Vaultwarden | https://pw.orfel.de |
| LibreChat | https://chat.orfel.de |
| ntfy | https://ntfy.orfel.de |
| n8n | https://n8n.orfel.de |
| Gitea | https://git.orfel.de |
| Home Assistant | https://home.orfel.de |
| Stirling PDF | https://pdf.orfel.de |

## 🐳 Docker Commands

### View all containers
```bash
docker ps
```

### View all containers (including stopped)
```bash
docker ps -a
```

### View logs for a container
```bash
docker logs -f <container-name>
```

### Execute command in container
```bash
docker exec -it <container-name> /bin/sh
```

### View Docker network
```bash
docker network inspect jannik-cloud-net
```

### Restart Docker
```bash
systemctl restart docker
```

## 🔐 Encryption Commands

### Encrypt all .env files
```bash
./scripts/encrypt-all-env.sh <age-public-key>
```

### Decrypt all .env.age files
```bash
./scripts/decrypt-secrets.sh /opt/Jannik-Cloud/keys/age-key.txt
```

### Generate new AGE key pair
```bash
./scripts/generate-age-key.sh
```

## 🛠️ Troubleshooting

### Service won't start
```bash
cd services/<service-name>
docker compose down
docker compose up -d
docker compose logs -f
```

### Check Caddy reverse proxy
```bash
cd caddy
docker compose logs -f
```

### Recreate Docker network
```bash
docker network rm jannik-cloud-net
docker network create jannik-cloud-net
sudo ./deploy_script.sh
```

### Verify AGE key
```bash
cat /opt/Jannik-Cloud/keys/age-key.txt
# Should start with: AGE-SECRET-KEY-
```

## 💾 Backup

### Backup all data
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz /mnt/Jannik-Cloud-Volume-01/
```

### Backup AGE key
```bash
cp /opt/Jannik-Cloud/keys/age-key.txt ~/age-key-backup.txt
```

## 🔄 Update Repository

```bash
cd /opt/Jannik-Cloud
git pull
sudo ./deploy_script.sh
```

## 📞 Support

- **Email**: jannik.mueller.jannik+git@googlemail.com
- **Domain**: orfel.de
