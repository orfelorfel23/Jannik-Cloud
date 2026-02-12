# Caddy Reverse Proxy

## Overview
Caddy is a reverse proxy that handles:
- Automatic HTTPS/TLS with Let's Encrypt certificates
- Routing to individual services based on domain
- Request compression and optimization
- WebSocket support for real-time services

## Configuration
- **Email**: jannik.mueller.jannik+git@googlemail.com
- **Domain**: orfel.de (with wildcard *.orfel.de)
- **Exposed Ports**: 80 (HTTP), 443 (HTTPS)

## Internal Routes
All services are routed through Caddy to their internal container ports:
- outline.orfel.de → outline:11000
- llm.orfel.de → litellm:11001
- port.orfel.de → portainer:11002
- owncloud.orfel.de → owncloud:11003
- nextcloud.orfel.de → nextcloud:11004
- wiki.orfel.de → mediawiki:11005
- br.orfel.de → baserow:11006
- pw.orfel.de → vaultwarden:11007
- chat.orfel.de → librechat:11008
- ntfy.orfel.de → ntfy:11009
- n8n.orfel.de → n8n:11010
- git.orfel.de → gitea:11011
- home.orfel.de → homeassistant:11012
- pdf.orfel.de → stirling-pdf:11013

## Certificates
HTTPS certificates are automatically obtained from Let's Encrypt and renewed 30 days before expiration. Email notifications are sent to jannik.mueller.jannik+git@googlemail.com.

## Logs
View Caddy logs:
```bash
docker logs caddy
```

## Network
Caddy is connected to the `jannik-cloud-net` Docker network and communicates with all services via container DNS.
