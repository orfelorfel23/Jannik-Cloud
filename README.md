# Jannik-Cloud

Self-hosted cloud infrastructure on Hetzner Ubuntu 24 LTS, managed via Docker Compose with automated deployment.

## Architecture

- **Reverse Proxy**: Caddy (automatic HTTPS via Let's Encrypt)
- **Database**: Shared PostgreSQL instance (one DB per service)
- **Cache**: Shared Redis instance
- **Secret Management**: AGE encryption for `.env` files
- **Domain**: `*.orfel.de` (wildcard DNS)

## Services

| Service | Subdomain (Clickable) | Port |
|---------|-----------------------|------|
| Caddy | — | 80, 443 |
| PostgreSQL | (internal) | 5432 |
| Redis | (internal) | 6379 |
| ArchiveBox | [archive.orfel.de](https://archive.orfel.de) | 884 |
| Authentik | [auth.orfel.de](https://auth.orfel.de) | 2884 |
| Baserow | [br.orfel.de](https://br.orfel.de) | 2273 |
| Bit | [bit.orfel.de](https://bit.orfel.de) | 811 |
| Clink | [clink.orfel.de](https://clink.orfel.de) | 6112 |
| Deezer | [deezer.orfel.de](https://deezer.orfel.de) | 673 |
| Gitea | [git.orfel.de](https://git.orfel.de) | 448 |
| Handbrake | [hb.orfel.de](https://hb.orfel.de) | 5800 |
| Home Assistant | [home.orfel.de](https://home.orfel.de) | 4663 |
| ILIAS | [ilias.orfel.de](https://ilias.orfel.de) | 45427 |
| ioBroker | [io.orfel.de](https://io.orfel.de) | 46 |
| Kestra | [kestra.orfel.de](https://kestra.orfel.de) | 5378 |
| LibreChat | [chat.orfel.de](https://chat.orfel.de) | 2428 |
| Linkding | [link.orfel.de](https://link.orfel.de) | 5465 |
| Linus (lsound) | [linus.orfel.de](https://linus.orfel.de), [lsound.orfel.de](https://lsound.orfel.de) | 1326 |
| LiteLLM | [llm.orfel.de](https://llm.orfel.de) | 556 |
| MediaWiki | [wiki.orfel.de](https://wiki.orfel.de) | 9454 |
| N8N | [n8n.orfel.de](https://n8n.orfel.de) | 686 |
| Nein | [nein.orfel.de](https://nein.orfel.de) | 8113 |
| Nextcloud | [nextcloud.orfel.de](https://nextcloud.orfel.de) | 6398 |
| NTFY | [ntfy.orfel.de](https://ntfy.orfel.de) | 6939 |
| OwnCloud (OCIS) | [owncloud.orfel.de](https://owncloud.orfel.de) | 696 |
| Outline | [outline.orfel.de](https://outline.orfel.de) | 688 |
| Portainer | [port.orfel.de](https://port.orfel.de) | 7678 |
| Quizmaster | [quiz.orfel.de](https://quiz.orfel.de) | 8223 |
| RustDesk Server | rust.orfel.de | 7878 |
| SearXNG | [go.orfel.de](https://go.orfel.de) | 3463 |
| Simple URL Shortener | [tiny.orfel.de](https://tiny.orfel.de) | 821 |
| Slash | [slash.orfel.de](https://slash.orfel.de) | 511 |
| Spoolman | [3d.orfel.de](https://3d.orfel.de) | 33 |
| Stirling PDF | [pdf.orfel.de](https://pdf.orfel.de) | 733 |
| Vaultwarden | [pw.orfel.de](https://pw.orfel.de) | 7277 |
| Webhook | [webhook.orfel.de](https://webhook.orfel.de) | 9500 |
| Zipline | [short.orfel.de](https://short.orfel.de) | 947 |

## First-Time Setup

### 1. Server Preparation

```bash
# Clone the repository
git clone https://github.com/orfelorfel23/Jannik-Cloud.git /opt/Jannik-Cloud
cd /opt/Jannik-Cloud
```

### 2. AGE Key Setup


The public key is already committed at `keys/age-public-key.txt`. The private key must **never** be committed to Git.


### 3. Generate Environment Files

For each service you want to deploy, run its `generate-env.sh`:

```bash
cd /opt/Jannik-Cloud/services/<service>
bash generate-env.sh
```

This generates the `.env` file with secure random passwords and encrypts it to `.env.age`. Commit the `.env.age` files to Git.

### 4. Enable Services

Each service has an empty `service.enabled` marker file. To disable a service:

```bash
rm services/<service>/service.enabled
```

To re-enable:

```bash
touch services/<service>/service.enabled
```

### 5. Deploy

```bash
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

The deploy script will:
1. Install Docker, age, fail2ban if missing
2. Prompt for the AGE private key if not found
3. Pull latest repo changes
4. Decrypt all `.env.age` files
5. Create persistent volume directories
6. Start infrastructure (PostgreSQL, Redis) first
7. Auto-create databases for services that need PostgreSQL
8. Start Caddy, then all remaining services

## Adding a New Service

1. Create `services/<service>/` with:
   - `docker-compose.yml`
   - `generate-env.sh`
   - `<service>.caddy` (Caddy reverse proxy fragment)
   - `service.enabled` (empty marker)
   - `README.md`
2. Run `bash generate-env.sh` to create `.env` and `.env.age`
3. Commit `.env.age` and all non-secret files
4. Re-run `deploy_script.sh`

## Removing a Service

```bash
rm services/<service>/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

The service containers will be stopped and removed, but **volumes and data are preserved**.

## Data Persistence

All persistent data is stored at `/mnt/Jannik-Cloud-Volume-01/<service>/`.

## Security

- All `.env` files are encrypted with AGE and never committed in plaintext
- fail2ban protects SSH access
- Only Caddy exposes ports 80/443 to the host — all other services are internal
- Private keys have `chmod 600`
