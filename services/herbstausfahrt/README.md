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

## Features & Architektur

- **Optimaler Treffpunkt (Fermat-Weber-Punkt):** Berechnung des optimalen Treffpunkts via Weiszfeld-Algorithmus, bei dem die Gesamtfahrstrecke aller Teilnehmer minimiert wird.
- **Side-by-Side Pin-Darstellung:** Standorte mit identischen Koordinaten (z. B. Schelli & Kai in Hainichen) werden automatisch horizontal nebeneinander aufgefächert, damit beide Icons immer sichtbar sind.
- **Keine Farbanzeige:** Die Fahrzeugfarben dienen ausschließlich der Icon-Zuordnung und werden in der Benutzeroberfläche nicht angezeigt.
- **Modernes Automotive-Design:** Glassmorphism UI, Dark-Mode-Tiles, animierter Treffpunkt-Radar und optionale Routing-Linien.
- **Kompakte Treffpunkt-Kachel:** Schlanke UI mit direktem Fokus- und Navigationsbutton ohne redundante Ortsbezeichner.
- **Teilnehmerliste (9 Fahrzeuge):** Vollständige Erfassung inklusive Tommy (Mondeo weiß) und Philipp (Seat Cupra blau) mit deterministischem Side-by-Side-Clustering in Hainichen und Chemnitz.

## Docker Build & Deployment

Das Docker-Image wird direkt gebaut und deployed:
- Server-Deployment via `deploy_script.sh` mit `docker compose build --no-cache` (oder Pull des Images).
- Lokaler Build & Push via:
  ```bash
  docker build -t git.orfel.de/jannik/herbstausfahrt:latest .
  docker push git.orfel.de/jannik/herbstausfahrt:latest
  ```
