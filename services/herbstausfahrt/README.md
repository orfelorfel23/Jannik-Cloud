# Herbstausfahrt — Karte

Interaktive Leaflet-Karte mit den Standorten der Herbstausfahrt und individuellen Auto-Icons.

## Service Details

- **Domain**: [karte.orfel.de](https://karte.orfel.de)
- **Container**: `herbstausfahrt`
- **Image**: `nginx:alpine`
- **Internal Port**: 80
- **Host Port**: `127.0.0.1:3850`
- **Reverse Proxy**: Caddy (`herbstausfahrt.caddy`)
- **Repository**: [Orfel-HermesAI-Bot/Herbstausfahrt](https://git.orfel.de/Orfel-HermesAI-Bot/Herbstausfahrt)
- **Content Volume**: `/mnt/Jannik-Cloud-Volume-01/herbstausfahrt/content`

## Automatischer Sync (service.init)

Über `service.init` wird das Repository direkt von Gitea auf den Server nach `/mnt/Jannik-Cloud-Volume-01/herbstausfahrt/content` geklont und bei jedem Deployment per `git pull` aktualisiert (analog zum JGA-Setup).
Änderungen an `locations.json` oder Icons, die in Gitea gepusht werden, sind nach dem Deployment sofort live, ohne dass manuell ein neues Docker-Image gebaut werden muss.
