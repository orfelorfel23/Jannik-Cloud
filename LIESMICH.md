<p align="center">
  <img src="services/dashboard/www/favicon.svg" alt="Jannik-Cloud Logo" width="128" />
</p>

<h1 align="center">Jannik-Cloud</h1>
<p align="center"><strong>Selbstgehostete Docker-Compose-Cloud-Infrastruktur mit AGE-verschlüsselten Secrets, Caddy Reverse Proxy und automatisiertem Deployment.</strong></p>

<p align="center">
  <a href="README.md">🇬🇧 English</a> · <a href="LIESMICH.md">🇩🇪 Deutsch</a>
</p>

---

## Überblick

**Jannik-Cloud** ist eine modulare, selbstgehostete Cloud-Infrastruktur auf Hetzner Ubuntu 24 LTS. Alle Dienste sind unter `services/<service>/` organisiert, über ein gemeinsames externes Docker-Netzwerk (`jannik-cloud-net`) verbunden und werden idempotent durch `deploy_script.sh` orchestriert.

```text
Internet (*.orfel.de :80/:443)
        │
        ▼
┌───────────────────────────────────────────┐
│        Caddy Reverse Proxy (HTTPS)        │
│   /mnt/.../caddy/fragments/*.caddy        │
└───────────────────┬───────────────────────┘
                    │  jannik-cloud-net (intern)
    ┌───────────────┼───────────────┬───────────────┐
    ▼               ▼               ▼               ▼
┌─────────┐   ┌──────────┐   ┌───────────┐   ┌────────────┐
│Postgres │   │  Redis   │   │   Gitea   │   │ 40+ App-   │
│  :5432  │   │  :6379   │   │   :448    │   │ Container  │
└─────────┘   └──────────┘   └───────────┘   └────────────┘
    │                                               │
    └──────────────► /mnt/Jannik-Cloud-Volume-01 ◄──┘
                            │
                            ▼
                Backup (rclone → Google Drive)
```

---

## Funktionen

- **Idempotentes Master-Deployment (`deploy_script.sh`)**: Jederzeit sicher wiederholbar; abgesichert durch einen `flock`-Lock (`/tmp/jannik-cloud-deploy.lock`), installiert fehlende Pakete (`docker`, `docker-compose-plugin`, `age`, `fail2ban`), richtet Swap (`4G`) und Zeitzone (`Europe/Berlin`) ein und konfiguriert einen täglichen Cronjob um `02:31` Uhr.
- **AGE-verschlüsselte Secret-Verwaltung**: `.env`-Dateien werden mit dem öffentlichen Schlüssel aus `keys/age-public-key.txt` in `.env.age` verschlüsselt und beim Deployment (oder über `decrypt-secrets.sh`) mit `chmod 600` sowie CRLF/BOM-Bereinigung entschlüsselt.
- **Automatische PostgreSQL-Provisionierung**: Die gemeinsame PostgreSQL-18-Instanz legt für jeden aktiven Dienst mit `NEEDS_POSTGRES=true` in der `.env` automatisch Datenbank (`<service>_db`) und Benutzer (`<service>_user`) an.
- **Service-Lifecycle-Hooks & Marker-Dateien**:
  - `service.enabled` – aktiviert oder deaktiviert einen Dienst sauber (deaktivierte Dienste werden gestoppt, persistente Volumes bleiben erhalten).
  - `service.backup` – Pre-Stop-Backup-Hooks vor Aktivierung des Wartungsmodus.
  - `service.init` – Initialisierungs-Hooks nach dem Start der Infrastruktur-Dienste.
  - `service.uid` – automatisches `chown` der Host-Volumes, falls ein Container bestimmte UIDs/GIDs benötigt.
- **Image-Vorbereitung ohne Downtime & Wartungsmodus**: Baut/zieht Images vor dem Stoppen laufender Container, schaltet Caddy während des Container-Neustarts kurzzeitig auf eine 503-Wartungsseite (wobei `git.orfel.de` für Init-Hooks online bleibt), prüft Healthchecks und stellt die Produktions-Fragmente wieder her.
- **Auto-Discovery-Dashboards (`scripts/generate_dashboards.py`)**: Durchsucht `services/*/service.enabled` und `*.caddy`, um sowohl `services.yaml` für **Homepage** als auch `data.json` für den eigenen **Jannik-Cloud Hub** automatisch zu erzeugen.
- **Automatisierte Google-Drive-Backups (`services/backup`)**: Tägliche Backups um `03:00` Uhr aus `pg_dumpall`-SQL-Dumps, `rclone sync` von `/mnt/Jannik-Cloud-Volume-01` und Rechte-Manifesten (`UID`/`GID`/Modus) mit 30 Tagen Aufbewahrung.
- **CI/CD-Webhooks & Ntfy-Benachrichtigungen**: HMAC-SHA256-authentifizierte GitHub-Webhooks (`services/webhook/hooks.json`) sowie Echtzeit-Meldungen über selbstgehostetes Ntfy.
- **Abgesicherter Host & Netzwerk-Schutz**: fail2ban-Jails (`sshd` im Aggressive-Modus, `recidive` und `caddy-scanner` über `nftables`), Docker-JSON-Log-Rotation (max. `50m`, `3` Dateien) sowie Caddy als einziger Dienst mit offenen Ports `80`/`443`.

---

## Funktionsweise & Tech-Stack

### Deployment-Ablauf (`deploy_script.sh`)

1. Lock `/tmp/jannik-cloud-deploy.lock` setzen und Start-Benachrichtigung an Ntfy senden.
2. Fehlende Pakete (`docker`, `age`, `fail2ban`) installieren, Docker-Log-Rotation, fail2ban-Jails, 4-GB-Swap, Zeitzone (`Europe/Berlin`) und den `02:31`-Cronjob einrichten.
3. Privaten AGE-Schlüssel unter `keys/age-key.txt` prüfen (fragt interaktiv nach, falls noch nicht vorhanden).
4. Repository in `/opt/Jannik-Cloud` klonen bzw. per `git reset --hard` aktualisieren und Ausführungsrechte wiederherstellen.
5. Externes Docker-Netzwerk `jannik-cloud-net` sicherstellen, aktive Dienste ermitteln (`docker-compose.yml` + `service.enabled`; GPU-Dienste werden ohne `nvidia-smi` übersprungen) und deaktivierte Dienste stoppen.
6. `.env*.age`-Dateien entschlüsseln, Verzeichnisse unter `/mnt/Jannik-Cloud-Volume-01/<service>` anlegen, `scripts/generate_dashboards.py` ausführen, verwaiste Docker-Ressourcen bereinigen und Images bauen bzw. pullen.
7. `service.backup`-Hooks ausführen, solange alle Container noch laufen.
8. Caddy-Wartungsmodus aktivieren (`gitea.caddy` bleibt dabei aktiv).
9. Infrastruktur geordnet starten (`postgres` → `redis` → `gitea`), PostgreSQL-Datenbanken anlegen und `service.init`-Hooks ausführen.
10. `service.uid`-Berechtigungen anwenden, alle übrigen Dienste starten (`docker compose up -d --remove-orphans`), Container-Health prüfen, Caddy wieder auf die Produktions-Fragmente umschalten, ungenutzte Images/Journale bereinigen und Abschlussmeldung an Ntfy senden.

### Dienste

| Dienst | Subdomain (anklickbar) | Port |
|--------|------------------------|------|
| Caddy | — | 80, 443 |
| PostgreSQL | (intern) | 5432 |
| Redis | (intern) | 6379 |
| Backup | (intern) | — |
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

## Voraussetzungen & Installation

### Voraussetzungen

- Ubuntu-24-LTS-Server (Root- bzw. `sudo`-Zugriff)
- Persistentes Storage-Volume unter `/mnt/Jannik-Cloud-Volume-01/`
- Wildcard-DNS für `*.orfel.de` auf den Server
- Privater AGE-Schlüssel (`AGE-SECRET-KEY-...`)

### 1. Repository klonen

```bash
git clone https://github.com/orfelorfel23/Jannik-Cloud.git /opt/Jannik-Cloud
cd /opt/Jannik-Cloud
```

### 2. AGE-Schlüssel einrichten

Der öffentliche AGE-Schlüssel liegt bereits unter `keys/age-public-key.txt`. Der private Schlüssel (`keys/age-key.txt`) darf **niemals** in Git eingecheckt werden. Beim ersten Lauf fragt `deploy_script.sh` nach dem privaten Schlüssel und speichert ihn mit `chmod 600`.

### 3. Umgebungsdateien generieren

Für jeden gewünschten Dienst das jeweilige `generate-env.sh` ausführen:

```bash
cd /opt/Jannik-Cloud/services/<service>
bash generate-env.sh
```

Dadurch wird eine `.env` mit sicheren Zufallspasswörtern erstellt und als `.env.age` verschlüsselt. Nur `.env.age` wird in Git eingecheckt.

### 4. Deploy ausführen

```bash
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

---

## Konfiguration

### Secrets & Entschlüsselung

- Alle `.env*.age`-Dateien lassen sich auch einzeln ohne vollständiges Deployment entschlüsseln:
  ```bash
  sudo bash /opt/Jannik-Cloud/decrypt-secrets.sh
  ```
- Die automatische PostgreSQL-Provisionierung liest `NEEDS_POSTGRES=true`, `DB_NAME`, `DB_USER` und `DB_PASSWORD` aus der jeweiligen `.env`.

### Datenhaltung & Aufbewahrung

- **Persistente Daten**: Alle Dienst-Volumes liegen unter `/mnt/Jannik-Cloud-Volume-01/<service>/`.
- **Google-Drive-Backup-Aufbewahrung** (`services/backup`): Dienstdaten werden per `rclone sync` gespiegelt; PostgreSQL-Dumps (`pg_dumpall`) und Rechte-Manifeste bleiben standardmäßig `30` Tage erhalten (`RETENTION_DAYS`).

### Sicherheitsmaßnahmen

- Alle `.env`-Dateien sind mit AGE verschlüsselt und werden niemals im Klartext eingecheckt.
- Private Schlüssel besitzen `chmod 600`.
- `fail2ban` schützt SSH (`maxretry = 2`, `bantime = 1w`, Aggressive-Modus), Wiederholungstäter (`recidive`) und Caddy vor Vulnerability-Scannern (`caddy-scanner`).
- Ausschließlich Caddy öffnet die Ports `80` und `443` nach außen.

---

## Nutzung

### Dienste aktivieren / deaktivieren

Jeder Dienst verwendet eine leere Marker-Datei `service.enabled`:

```bash
# Dienst deaktivieren (stoppt Container beim nächsten Deploy, Volumes bleiben erhalten)
rm services/<service>/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh

# Dienst wieder aktivieren
touch services/<service>/service.enabled
sudo bash /opt/Jannik-Cloud/deploy_script.sh
```

### Neuen Dienst hinzufügen

1. Verzeichnis `services/<service>/` anlegen mit:
   - `docker-compose.yml`
   - `generate-env.sh`
   - `<service>.caddy` (Caddy-Reverse-Proxy-Fragment)
   - `service.enabled` (leere Marker-Datei)
   - `README.md`
2. `bash generate-env.sh` ausführen, um `.env` und `.env.age` zu erzeugen.
3. `.env.age` und alle nicht-geheimen Dateien in Git committen.
4. `sudo bash /opt/Jannik-Cloud/deploy_script.sh` ausführen.

### Manuelle Backups & Webhooks

- **Manuelles Backup starten**:
  ```bash
  docker exec -it backup /app/backup.sh
  ```
- **Webhook-Endpunkte** (`https://webhook.orfel.de/hooks/<id>`, per `X-Hub-Signature-256` und `WEBHOOK_SECRET` mit HMAC-SHA256 abgesichert):
  - `deploy-cloud` – führt das vollständige `deploy_script.sh` aus
  - `rebuild-linus` – baut den `linus`-Container neu
  - `rebuild-cbrn` – baut den `cbrn`-Container neu

### Push-Benachrichtigungen (Ntfy)

Echtzeit-Benachrichtigungen über selbstgehostetes Ntfy abonnieren:
1. [Ntfy Web App](https://ntfy.orfel.de/Jannik-Cloud-Deploy-Trigger) öffnen oder die offizielle **Ntfy**-App (iOS/Android) installieren.
2. Auf **+** (Abonnieren) tippen, „Anderen Server verwenden“ aktivieren und `https://ntfy.orfel.de` eintragen.
3. Das Topic `Jannik-Cloud-Deploy-Trigger` abonnieren.

Es werden Benachrichtigungen für Webhook-Pushes, `deploy_script.sh`-Starts (manuell, per Webhook oder per `02:31`-Cronjob), erfolgreiche Abschlüsse, Backup-Status und kritische Fehler zugestellt.

---

## Projektstruktur

```text
Jannik-Cloud/
├── keys/
│   └── age-public-key.txt         # Öffentlicher AGE-Schlüssel (age-key.txt bleibt nur auf dem Server)
├── scripts/
│   └── generate_dashboards.py     # Auto-Discovery-Generator für Homepage & Hub data.json
├── services/
│   ├── caddy/                     # Caddyfile, Compose & Wartungsseiten-Vorlagen
│   ├── postgres/                  # Gemeinsame PostgreSQL-18-Instanz
│   ├── redis/                     # Gemeinsamer Redis-Cache
│   ├── backup/                    # Google-Drive-Backup-Container (rclone + pg_dumpall)
│   ├── dashboard/                 # Eigener Jannik-Cloud Hub (dash.orfel.de / hub.orfel.de)
│   ├── homepage/                  # Homepage-Dashboard (homepage.orfel.de)
│   ├── webhook/                   # GitHub-HMAC-Webhook-Empfänger (hooks.json + scripts/)
│   └── <service>/                 # Einzelne Dienste (docker-compose.yml, *.caddy, .env.age, service.enabled)
├── decrypt-secrets.sh             # Eigenständiges Hilfsskript zur AGE-Entschlüsselung
└── deploy_script.sh               # Idempotentes Master-Deployment-Skript
```

---

## Lizenz

Privates / internes Projekt. Öffentlich ohne separate Open-Source-`LICENSE`-Datei gehostet.
