# Mind-o-Mat Service

Lokales Second-Brain-System mit Cloud-Sync. Webapp + QMD-Suche + Notes-API in einem Image.

## Subdomain

- **https://mindomat.orfel.de** — Webapp (Graph, Cluster-Karte, Radial, Editor)
- **QMD**: intern im Container, Port 8181, von Webapp über `localhost:8181` angesprochen

## Architektur

```
Internet → Caddy (HTTPS, *.orfel.de)
                ↓ mindomat.orfel.de
        mindomat-app:5173 (intern)
        ├── Webapp (Vite + React + Cytoscape + Tiptap)
        ├── Notes-API-Proxy + HMAC-Auth
        └── qmd:8181 (im selben Container, MCP/HTTP-Server fuer die Suche)
                          ↓
                   /mnt/Jannik-Cloud-Volume-01/mindomat-vault (Notizen)
                          ↓
        /mnt/Jannik-Cloud-Volume-01/mindomat-qmd (Embeddings)
```

## Auto-Deploy via Jannik-Cloud `deploy_script.sh`

Das `service.init`-Skript wird automatisch aufgerufen, wenn der Service das erste Mal aktiviert wird:

1. **Vault** wird angelegt in `/mnt/Jannik-Cloud-Volume-01/mindomat-vault/`
2. **12 Standardordner** + `Konfig.md` werden erstellt
3. **git init** falls noetig
4. **QMD-Collections** werden dokumentiert (manueller Schritt im Container)
5. **service.enabled**-Marker bleibt gesetzt

Das `service.backup`-Skript wird vor jedem Container-Stop aufgerufen:
- **Vault-Backup** als tar.gz in `~/mindomat_backups/`
- **QMD-Embeddings-Backup** als tar.gz
- Cleanup der letzten 5 Backups

## First-Time Setup auf VPS

```bash
# 1. Service aktivieren (einmalig, manuell auf dem VPS)
touch /opt/Jannik-Cloud/services/mindomat/service.enabled

# 2. Vault initialisieren
sudo bash /opt/Jannik-Cloud/services/mindomat/service.init

# 3. .env generieren (mit AGE-Verschluesselung)
cd /opt/Jannik-Cloud/services/mindomat
bash generate-env.sh
# .env und .env.age werden erzeugt
# .env.age committen, .env lokal behalten

# 4. QMD-Collections einrichten (einmalig nach Container-Start)
docker compose exec mindomat-app sh
qmd collection add /vault/00_Inbox --name inbox
qmd collection add /vault/01_Daily --name daily
qmd collection add /vault/10_Wiki --name wiki
qmd collection add /vault/20_Projekte --name projekte
qmd embed
exit

# 5. Deploy
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

## Manuelle Befehle (vom VPS aus)

```bash
# In den Container einsteigen
docker compose exec mindomat-app sh

# Im Container:
# Vault indexieren
node /opt/mindomat/tool/bin/mindomat.mjs index --vault /vault

# Notiz ingestieren (mit --mock fuer Tests)
node /opt/mindomat/tool/bin/mindomat.mjs ingest --vault /vault --mock

# Sync zu gitea
node /opt/mindomat/tool/bin/mindomat.mjs sync --vault /vault

# Watch-Mode fuer automatischen Ingest
node /opt/mindomat/tool/bin/mindomat.mjs ingest --vault /vault --watch
```

## Volumes

- `/mnt/Jannik-Cloud-Volume-01/mindomat-vault` — Vault (Notizen, Wiki, Konfig)
- `/mnt/Jannik-Cloud-Volume-01/mindomat-qmd` — QMD-Embeddings

## Backups

Auto-Backup via `service.backup` (vor jedem Deploy):

```bash
ls -la ~/mindomat_backups/
# mindomat_vault_20260905_120000.tar.gz
# mindomat_qmd_20260905_120000.tar.gz
```

Plus: jeder `mindomat sync` pusht den Vault automatisch zu gitea (Git-History).

Plus: Jannik-Cloud-uebergeordnete Backup-Strategie (siehe Jannik-Cloud `docs/BACKUP.md`).

## Tech-Stack

- **Webapp:** Vite + React + TypeScript + Cytoscape + Tiptap
- **QMD:** `@tobilu/qmd` (BM25 + Vektor + LLM-Re-Ranking, ~2 GB Modelle)
- **Server:** Express + http-proxy-middleware
- **Auth:** HMAC-SHA256 Bearer-Token (optional)
- **Reverse-Proxy:** Caddy (extern, automatische HTTPS)
- **Secrets:** AGE-verschluesselt in `.env.age`
- **Init-Hook:** `service.init` (Vault-Setup)
- **Backup-Hook:** `service.backup` (Vault + QMD-Backup)

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

Image wird automatisch neu gebaut (Multi-Stage-Build in `Dockerfile`).
