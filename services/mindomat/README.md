# Mind-o-Mat — Lokales Second-Brain-System

Lokales Second-Brain-System mit Cloud-Sync. Webapp + QMD-Suche + Notes-API in einem vorkompilierten Docker-Container (Ziel-Workflow).

## Subdomains

- **https://mindomat.orfel.de** — Primäre Webapp-URL (Graph, Cluster-Karte, Radial, Editor)
- **https://mind.orfel.de** — Kurz-Alias
- **https://mom.orfel.de** — Initialen-Alias
- **QMD**: intern im Container, Port 8181 (MCP/HTTP-Server für lokale Suche)

## Architektur

```
Internet → Caddy (HTTPS, *.orfel.de)
                ↓ mindomat.orfel.de / mind.orfel.de / mom.orfel.de
        mindomat-app:5173 (git.orfel.de/jannik/mindomat:latest)
        ├── Webapp (Vite + React + Cytoscape + Tiptap)
        ├── Integrierter Notes-API Server + HMAC-Auth
        └── qmd:8181 (im selben Container, MCP/HTTP-Server fuer die Suche)
                          ↓
                   /mnt/Jannik-Cloud-Volume-01/mindomat-vault (Notizen)
                          ↓
         /mnt/Jannik-Cloud-Volume-01/mindomat-qmd (Embeddings)
```

## Deployment via Jannik-Cloud `deploy_script.sh`

Mind-o-Mat nutzt den **Ziel-Workflow (Standard)**:
1. Das Image wird lokal im Repo `C:\GitHub\Mind-o-Mat` gebaut und in die Gitea Container Registry gepusht:
   `docker build -t git.orfel.de/jannik/mindomat:latest .`
   `docker push git.orfel.de/jannik/mindomat:latest`
2. Der Hetzner-Server zieht das fertige Image via `docker compose pull` und startet den Container.

Das `service.init`-Skript wird automatisch aufgerufen, wenn der Service das erste Mal aktiviert wird:
1. **Vault** wird initialisiert (klont automatisch `https://git.orfel.de/Jannik/Mind-o-Mat-Vault.git` falls vorhanden)
2. **QMD-Collections** werden vorbereitet
3. **service.enabled**-Marker bleibt gesetzt

Das `service.backup`-Skript wird vor jedem Container-Stop aufgerufen:
- **Vault-Backup** als tar.gz in `~/mindomat_backups/`
- **QMD-Embeddings-Backup** als tar.gz
- Automatische Bereinigung alter Backups (letzte 5 werden behalten)

## First-Time Setup auf VPS

```bash
# 1. Service aktivieren
touch /opt/Jannik-Cloud/services/mindomat/service.enabled

# 2. Vault initialisieren
sudo bash /opt/Jannik-Cloud/services/mindomat/service.init

# 3. .env generieren (mit AGE-Verschluesselung)
cd /opt/Jannik-Cloud/services/mindomat
bash generate-env.sh

# 4. Deploy ausführen
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

## Volumes

- `/mnt/Jannik-Cloud-Volume-01/mindomat-vault` — Vault (Notizen, Wiki, Konfig)
- `/mnt/Jannik-Cloud-Volume-01/mindomat-qmd` — QMD-Embeddings

## Tech-Stack

- **Webapp:** Vite + React + TypeScript + Cytoscape + Tiptap
- **QMD:** `@tobilu/qmd` (BM25 + Vektor + LLM-Re-Ranking)
- **Server:** Node.js Express (statische Dateien + native Notes-API)
- **Auth:** HMAC-SHA256 Bearer-Token
- **Reverse-Proxy:** Caddy (automatische HTTPS für alle 3 Subdomains)
- **Secrets:** AGE-verschlüsselt in `.env.age`
