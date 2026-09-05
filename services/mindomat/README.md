# Mind-o-Mat Service

Lokales Second-Brain-System mit Cloud-Sync. Webapp + QMD-Suche + Notes-API.

## Subdomain

- **https://mindomat.orfel.de** — Webapp (Graph, Cluster-Karte, Radial, Editor)

## Architektur

```
Internet → Caddy (HTTPS, *.orfel.de)
                ↓
        mindomat-webapp:5173
        ├── statische Frontend-Dateien (dist/)
        └── /api/* → mindomat-tool:3000 (Notes-API)
                          ↓
                   /vault-Volume (mindomat-vault)
                          ↓
                   mindomat-qmd:8181 (MCP/HTTP)
                          ↓ (read-only Mount)
                   /vault-Volume
```

## Komponenten

| Service | Zweck | Port | Image |
|---|---|---|---|
| `webapp` | Vite-React-Frontend + Notes-API-Proxy + Auth | 5173 | lokal gebaut |
| `qmd` | Lokale Hybridsuche (BM25 + Vektor + Re-Ranking) | 8181 | lokal gebaut |

Beachte: Der Tool-Container (das eigentliche `mindomat index`/`ingest`/`sync`) läuft NICHT als dauerhafter Service. Stattdessen wird er manuell per SSH aufgerufen, wenn ein Ingest nötig ist.

## Volumes

- `/mnt/Jannik-Cloud-Volume-01/mindomat-vault` — Vault (Notizen)
- `/mnt/Jannik-Cloud-Volume-01/mindomat-qmd` — QMD-Cache + Embeddings

## First-Time Setup

```bash
# 1. Vault-Init (einmalig)
sudo bash /opt/Jannik-Cloud/services/mindomat/init-vault.sh

# 2. .env generieren (mit AGE-Verschluesselung)
cd /opt/Jannik-Cloud/services/mindomat
bash generate-env.sh
# .env wurde erzeugt + .env.age generiert
# .env.age committen, .env lokal behalten

# 3. Webapp + QMD bauen + starten
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

## QMD-Collections einrichten (einmalig nach Start)

```bash
# QMD-Container-Shell
docker compose exec qmd sh

# Im Container:
qmd collection add /vault/00_Inbox --name inbox
qmd collection add /vault/01_Daily --name daily
qmd collection add /vault/10_Wiki --name wiki
qmd collection add /vault/20_Projekte --name projekte
qmd embed
```

## Notes-API Auth (optional, fuer Produktion)

Wenn `NOTES_API_TOKEN` in `.env` gesetzt ist, verlangt die Notes-API einen Bearer-Token.

**Token generieren** (lokal):

```bash
NOTES_API_TOKEN=$(grep NOTES_API_TOKEN .env | cut -d= -f2)
node scripts/token-gen.mjs
# Output: <timestamp>.<hmac-hex>
```

Im Token steckt der gleiche `NOTES_API_TOKEN` aus der `.env` (HMAC-Secret). Die Webapp nutzt es für Schreibzugriffe, Lesen ist offen.

## Manuelle Befehle (vom VPS aus)

```bash
# Vault-Index neu erstellen
docker compose run --rm webapp node ../node_modules/.bin/mindomat index --vault /vault

# Ingest: eine Notiz verarbeiten
docker compose run --rm webapp node ../node_modules/.bin/mindomat ingest --vault /vault --mock

# Sync zu gitea
docker compose run --rm webapp node ../node_modules/.bin/mindomat sync --vault /vault

# Watch-Mode: lauscht auf neue Inbox-Notizen
docker compose run --rm webapp node ../node_modules/.bin/mindomat ingest --vault /vault --watch
```

## Backups

Vault-Daten liegen in `/mnt/Jannik-Cloud-Volume-01/mindomat-vault/`. Sie sind:

1. **Git-history** in gitea (`https://git.orfel.de/Jannik/Mind-o-Mat-Vault`) — automatisch via `mindomat sync`
2. **Lokales Volume** auf dem VPS
3. **Pre-Deployment-Backup** via `service.backup` (in `deploy_script.sh`)

Siehe Jannik-Cloud-`docs/BACKUP.md` fuer die uebergeordnete Backup-Strategie.

## Deaktivieren / Reaktivieren

```bash
# Deaktivieren
rm /opt/Jannik-Cloud/services/mindomat/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh

# Reaktivieren
touch /opt/Jannik-Cloud/services/mindomat/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

## Versions-Updates

```bash
cd /opt/Jannik-Cloud
git pull
sudo bash deploy_script.sh
```

Webapp-Image wird automatisch neu gebaut (Multi-Stage-Build in `webapp/Dockerfile`).
QMD-Image wird neu gebaut.

## Tech-Stack

- **Webapp:** Vite + React + TypeScript + Cytoscape + Tiptap (Tabelle `services/mindomat/webapp/`)
- **QMD:** `@tobilu/qmd` (~2 GB GGUF-Modelle lokal)
- **Server:** Express + http-proxy-middleware fuer API-Proxy
- **Auth:** HMAC-SHA256 Bearer-Token (optional)
- **Reverse-Proxy:** Caddy (extern, automatische HTTPS)
- **Secrets:** AGE-verschluesselt in `.env.age`
