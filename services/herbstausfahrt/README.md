# Herbstausfahrt — Karte

Interaktive Leaflet-Karte mit den Standorten der Herbstausfahrt und individuellen Auto-Icons.

## Service Details

- **Domain**: [karte.orfel.de](https://karte.orfel.de)
- **Container**: `herbstausfahrt`
- **Image**: `git.orfel.de/jannik/herbstausfahrt:latest`
- **Internal Port**: 80
- **Host Port**: `127.0.0.1:3850`
- **Reverse Proxy**: Caddy (`herbstausfahrt.caddy`)
- **Repository**: [Orfel-HermesAI-Bot/Herbstausfahrt](https://git.orfel.de/Orfel-HermesAI-Bot/Herbstausfahrt)

## Updates & Deployment

Das Image wird lokal gebaut und in die Gitea Container Registry gepusht:
```bash
docker build -t git.orfel.de/jannik/herbstausfahrt:latest .
docker push git.orfel.de/jannik/herbstausfahrt:latest
```
Der Server zieht sich das fertige Image via `deploy_script.sh` und startet den Container neu.
