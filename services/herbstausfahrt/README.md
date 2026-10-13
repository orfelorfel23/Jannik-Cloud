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

## Docker Build & Deployment

Das Docker-Image wird direkt aus dem Gitea-Repository gebaut (analog zu `linus` und `spotify`):
- `Dockerfile` klont das Repository (`https://git.orfel.de/Orfel-HermesAI-Bot/Herbstausfahrt.git`) im Build-Schritt.
- Beim Server-Deployment (`deploy_script.sh`) wird das Image via `docker compose build --no-cache` auf dem Server gebaut.
- Alternativ kann das Image auch lokal gebaut und in die Gitea Container Registry gepusht werden:
  ```bash
  docker compose build
  docker push git.orfel.de/jannik/herbstausfahrt:latest
  ```
