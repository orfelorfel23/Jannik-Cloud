<p align="center">
  <img src="services/dashboard/www/favicon.svg" alt="Jannik-Cloud Logo" width="128" />
</p>

<h1 align="center">Jannik-Cloud</h1>
<p align="center"><strong>Self-hosted Docker Compose cloud infrastructure with AGE-encrypted secrets, Caddy reverse proxy, and automated deployment.</strong></p>

<p align="center">
  <a href="README.md">🇬🇧 English</a> · <a href="LIESMICH.md">🇩🇪 Deutsch</a>
</p>

---

## Overview

**Jannik-Cloud** is a modular, self-hosted cloud infrastructure running on Hetzner Ubuntu 24 LTS. All services are organized under `services/<service>/`, connected via a shared external Docker network (`jannik-cloud-net`), and orchestrated idempotently by `deploy_script.sh`.

```text
Internet (*.orfel.de :80/:443)
        │
        ▼
┌───────────────────────────────────────────┐
│        Caddy Reverse Proxy (HTTPS)        │
│   /mnt/.../caddy/fragments/*.caddy        │
└───────────────────┬───────────────────────┘
                    │  jannik-cloud-net (internal)
    ┌───────────────┼───────────────┬───────────────┐
    ▼               ▼               ▼               ▼
┌─────────┐   ┌──────────┐   ┌───────────┐   ┌────────────┐
│Postgres │   │  Redis   │   │   Gitea   │   │ 40+ App    │
│  :5432  │   │  :6379   │   │   :448    │   │ Containers │
└─────────┘   └──────────┘   └───────────┘   └────────────┘
    │                                               │
    └──────────────► /mnt/Jannik-Cloud-Volume-01 ◄──┘
                            │
                            ▼
                Backup (rclone → Google Drive)
```

---

## Features

- **Idempotent Master Deployment (`deploy_script.sh`)**: Safe to re-run at any time; protected by an `flock` lock (`/tmp/jannik-cloud-deploy.lock`), automatically installs missing packages (`docker`, `docker-compose-plugin`, `age`, `fail2ban`), configures swap (`4G`), sets timezone (`Europe/Berlin`), and schedules daily cron runs at `02:31`.
- **AGE-Encrypted Secret Management**: `.env` files are encrypted to `.env.age` using the public key in `keys/age-public-key.txt` and decrypted at deploy time (or via `decrypt-secrets.sh`) with `chmod 600` and CRLF/BOM sanitization.
- **Automatic PostgreSQL Provisioning**: Shared PostgreSQL 18 instance automatically creates `<service>_db` and `<service>_user` for every active service with `NEEDS_POSTGRES=true` in its `.env`.
- **Service Lifecycle Hooks & Marker Files**:
  - `service.enabled` – enables or disables a service cleanly (deactivated services are stopped while preserving persistent volumes).
  - `service.backup` – pre-stop backup hooks executed before maintenance mode.
  - `service.init` – per-service initialization hooks executed after infrastructure startup.
  - `service.uid` – automatic `chown` of host volumes when specific container UIDs/GIDs are required.
- **Zero-Downtime Image Preparation & Maintenance Mode**: Builds/pulls images before stopping containers, switches Caddy temporarily to a 503 maintenance page (keeping `git.orfel.de` online for init hooks), verifies container health, and restores production Caddy fragments.
- **Auto-Discovered Dashboards (`scripts/generate_dashboards.py`)**: Scans `services/*/service.enabled` and `*.caddy` files to regenerate both the **Homepage** `services.yaml` and the custom **Jannik-Cloud Hub** `data.json`.
- **Automated Google Drive Backups (`services/backup`)**: Daily `03:00` backups combining `pg_dumpall` SQL dumps, `rclone sync` of `/mnt/Jannik-Cloud-Volume-01`, and file permission manifests (`UID`/`GID`/mode) with 30-day retention.
- **CI/CD Webhooks & Ntfy Notifications**: HMAC-SHA256 authenticated GitHub webhook endpoints (`services/webhook/hooks.json`) and real-time deployment/backup notifications via self-hosted Ntfy.
- **Hardened Host & Network Security**: fail2ban jails (`sshd` aggressive mode, `recidive`, and `caddy-scanner` via `nftables`), Docker JSON log rotation (`50m` max size, `3` files), and Caddy as the only service exposing ports `80`/`443`.

---

## How It Works & Tech Stack

### Deployment Lifecycle (`deploy_script.sh`)

1. Acquire `/tmp/jannik-cloud-deploy.lock` and send start notification to Ntfy.
2. Install missing packages (`docker`, `age`, `fail2ban`), configure Docker log rotation, fail2ban jails, 4 GB swap, timezone (`Europe/Berlin`), and `02:31` cron job.
3. Validate the AGE private key at `keys/age-key.txt` (prompts interactively if absent).
4. Clone or `git reset --hard` the repository in `/opt/Jannik-Cloud` and restore script permissions.
5. Ensure external Docker network `jannik-cloud-net`, discover active services (`docker-compose.yml` + `service.enabled`, skipping GPU services if `nvidia-smi` is absent), and stop deactivated services.
6. Decrypt `.env*.age` files, create `/mnt/Jannik-Cloud-Volume-01/<service>` directories, run `scripts/generate_dashboards.py`, prune dangling Docker resources, and pull/build images.
7. Run `service.backup` hooks while containers are still online.
8. Enable Caddy maintenance mode (preserving `gitea.caddy`).
9. Start infrastructure in order (`postgres` → `redis` → `gitea`), provision PostgreSQL databases, and run `service.init` hooks.
10. Apply `service.uid` permissions, start all remaining services (`docker compose up -d --remove-orphans`), verify container health/restarts, switch Caddy back to production fragments, prune unused images/journals, and send completion status to Ntfy.

### Services

| Service | Subdomain (Clickable) | Port |
|---------|-----------------------|------|
| Caddy | — | 80, 443 |
| PostgreSQL | (internal) | 5432 |
| Redis | (internal) | 6379 |
| Backup | (internal) | — |
| Dashboard / Hub | [dash.orfel.de](https://dash.orfel.de), [hub.orfel.de](https://hub.orfel.de) | 3006 |
| Homepage | [homepage.orfel.de](https://homepage.orfel.de) | 3005 |
| ArchiveBox | [archive.orfel.de](https://archive.orfel.de) | 884 |
| Authentik | [auth.orfel.de](https://auth.orfel.de) | 2884 |
| Baserow | [br.orfel.de](https://br.orfel.de) | 2273 |
| Bit | [bit.orfel.de](https://bit.orfel.de) | 811 |
| Clink | [clink.orfel.de](https://clink.orfel.de) | 6112 |
| Deezer | [deezer.orfel.de](https://deezer.orfel.de) | 673 |
| Gitea | [git.orfel.de](https://git.orfel.de) | 448 |
| Handbrake | [hb.orfel.de](https://hb.orfel.de) | 5800 |
| Herbstausfahrt | [karte.orfel.de](https://karte.orfel.de) | 3850 |
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
| Navidrome | [music.orfel.de](https://music.orfel.de) | 7664 |
| Nein | [nein.orfel.de](https://nein.orfel.de) | 8113 |
| Nextcloud | [nextcloud.orfel.de](https://nextcloud.orfel.de) | 6398 |
| NTFY | [ntfy.orfel.de](https://ntfy.orfel.de) | 6939 |
| OwnCloud (OCIS) | [owncloud.orfel.de](https://owncloud.orfel.de) | 696 |
| Outline | [outline.orfel.de](https://outline.orfel.de) | 688 |
| Portainer | [port.orfel.de](https://port.orfel.de) | 7678 |
| RustDesk Server | rust.orfel.de | 7878 |
| SearXNG | [go.orfel.de](https://go.orfel.de) | 3463 |
| Simple URL Shortener | [tiny.orfel.de](https://tiny.orfel.de) | 821 |
| Slash | [slash.orfel.de](https://slash.orfel.de) | 511 |
| [Solus](services/solus/README.md) | [solus.orfel.de](https://solus.orfel.de) | 8787 |
| Spoolman | [3d.orfel.de](https://3d.orfel.de) | 33 |
| Stirling PDF | [pdf.orfel.de](https://pdf.orfel.de) | 733 |
| Syncthing | [sync.orfel.de](https://sync.orfel.de) | 7962 |
| Vaultwarden | [pw.orfel.de](https://pw.orfel.de) | 7277 |
| Viz | [viz.orfel.de](https://viz.orfel.de) | 849 |
| [Mind-o-Mat](services/mindomat/README.md) | [mindomat.orfel.de](https://mindomat.orfel.de), [mind.orfel.de](https://mind.orfel.de), [mom.orfel.de](https://mom.orfel.de) | 5173 |
| Webhook | [webhook.orfel.de](https://webhook.orfel.de) | 9500 |
| Zipline | [short.orfel.de](https://short.orfel.de) | 947 |
| XBackBone | [image.orfel.de](https://image.orfel.de), [bild.orfel.de](https://bild.orfel.de), [bilder.orfel.de](https://bilder.orfel.de) | 948 |

---

## Prerequisites & Installation

### Prerequisites

- Ubuntu 24 LTS server (root / `sudo` access)
- Persistent storage volume mounted at `/mnt/Jannik-Cloud-Volume-01/`
- Wildcard DNS pointing `*.orfel.de` to the host
- Your AGE private key (`AGE-SECRET-KEY-...`)

### 1. Clone the Repository

```bash
git clone https://github.com/orfelorfel23/Jannik-Cloud.git /opt/Jannik-Cloud
cd /opt/Jannik-Cloud
```

### 2. AGE Key Setup

The AGE public key is committed at `keys/age-public-key.txt`. The private key (`keys/age-key.txt`) must **never** be committed to Git. `deploy_script.sh` prompts for it on first run and saves it with `chmod 600`.

### 3. Generate Environment Files

For each service you want to configure, run its `generate-env.sh`:

```bash
cd /opt/Jannik-Cloud/services/<service>
bash generate-env.sh
```

This generates `.env` with secure random passwords and encrypts it to `.env.age`. Commit only `.env.age` to Git.

### 4. Deploy

```bash
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

---

## Configuration

### Secrets & Environment Decryption

- To decrypt all `.env*.age` files manually without running a full deploy:
  ```bash
  sudo bash /opt/Jannik-Cloud/decrypt-secrets.sh
  ```
- PostgreSQL auto-provisioning reads `NEEDS_POSTGRES=true`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD` from a service's `.env`.

### Persistent Storage & Retention

- **Data Persistence**: All service volumes are stored under `/mnt/Jannik-Cloud-Volume-01/<service>/`.
- **Google Drive Backup Retention** (`services/backup`): Service data is mirrored via `rclone sync`; PostgreSQL dumps (`pg_dumpall`) and permission manifests are retained for `30` days by default (`RETENTION_DAYS`).

### Security Controls

- All `.env` files are encrypted with AGE and never committed in plaintext.
- Private keys have `chmod 600`.
- `fail2ban` protects SSH (`maxretry = 2`, `bantime = 1w`, aggressive mode), repeat offenders (`recidive`), and Caddy vulnerability scans (`caddy-scanner`).
- Only Caddy exposes ports `80` and `443` to the public internet.

---

## Usage

### Enabling / Disabling Services

Each service uses an empty `service.enabled` marker file:

```bash
# Disable a service (stops containers on next deploy, preserves volumes)
rm services/<service>/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh

# Re-enable a service
touch services/<service>/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

### Adding a New Service

1. Create `services/<service>/` containing:
   - `docker-compose.yml`
   - `generate-env.sh`
   - `<service>.caddy` (Caddy reverse proxy fragment)
   - `service.enabled` (empty marker file)
   - `README.md`
2. Run `bash generate-env.sh` to generate `.env` and `.env.age`.
3. Commit `.env.age` and all non-secret files.
4. Run `sudo bash /opt/Jannik-Cloud/deploy_script.sh`.

### Manual Backups & Webhooks

- **Trigger manual backup**:
  ```bash
  docker exec -it backup /app/backup.sh
  ```
- **Webhook endpoints** (`https://webhook.orfel.de/hooks/<id>`, HMAC-SHA256 verified via `X-Hub-Signature-256` and `WEBHOOK_SECRET`):
  - `deploy-cloud` – executes the full `deploy_script.sh`
  - `rebuild-linus` – rebuilds the `linus` container
  - `rebuild-cbrn` – rebuilds the `cbrn` container

### Push Notifications (Ntfy)

Subscribe to real-time deployment and backup events via self-hosted Ntfy:
1. Open the [Ntfy Web App](https://ntfy.orfel.de/Jannik-Cloud-Deploy-Trigger) or install the official **Ntfy** iOS/Android app.
2. Tap **+** (Subscribe), enable **Use another server**, and enter `https://ntfy.orfel.de`.
3. Subscribe to topic `Jannik-Cloud-Deploy-Trigger`.

You will receive notifications for webhook-triggered pushes, `deploy_script.sh` starts (manual, webhook, or `02:31` cron), successful completions, backup statuses, and critical failures.

---

## Project Structure

```text
Jannik-Cloud/
├── keys/
│   └── age-public-key.txt         # Public AGE key (private age-key.txt stays on server only)
├── scripts/
│   └── generate_dashboards.py     # Auto-discovery generator for Homepage & Hub data.json
├── services/
│   ├── caddy/                     # Caddyfile, compose & maintenance page templates
│   ├── postgres/                  # Shared PostgreSQL 18 service
│   ├── redis/                     # Shared Redis cache
│   ├── backup/                    # Google Drive rclone + pg_dumpall backup container
│   ├── dashboard/                 # Custom Jannik-Cloud Hub (dash.orfel.de / hub.orfel.de)
│   ├── homepage/                  # Homepage dashboard (homepage.orfel.de)
│   ├── webhook/                   # GitHub HMAC webhook receiver (hooks.json + scripts/)
│   └── <service>/                 # Individual services (docker-compose.yml, *.caddy, .env.age, service.enabled)
├── decrypt-secrets.sh             # Standalone AGE decryption helper
└── deploy_script.sh               # Idempotent master deployment script
```

---

## License

Private / Internal Project. Hosted publicly without a separate open-source `LICENSE` file.
