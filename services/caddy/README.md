# Caddy — Reverse Proxy

Caddy serves as the single entry point for all web traffic, providing automatic HTTPS via Let's Encrypt.

## Ports

- `80` — HTTP (redirects to HTTPS)
- `443` — HTTPS

## Configuration

- **Caddyfile**: Contains global options and imports all `*.caddy` fragment files
- **Fragments**: Each service provides its own `.caddy` file with reverse proxy rules
- Fragments are assembled into `/mnt/Jannik-Cloud-Volume-01/caddy/fragments/` by the deploy script

## Persistent Data

- `/mnt/Jannik-Cloud-Volume-01/caddy/data` — TLS certificates and state
- `/mnt/Jannik-Cloud-Volume-01/caddy/config` — Caddy configuration
- `/mnt/Jannik-Cloud-Volume-01/caddy/fragments` — Service proxy fragments
