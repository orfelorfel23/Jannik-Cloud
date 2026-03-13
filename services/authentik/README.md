# Authentik — Identity Provider

## Subdomain
`auth.orfel.de`

## Port Mapping
`127.0.0.1:2884:9000`

## Containers
- `authentik-server` — main web UI and API
- `authentik-worker` — background task worker

## Dependencies
- Shared PostgreSQL
- Shared Redis

## Persistent Data
- `/mnt/Jannik-Cloud-Volume-01/authentik/media/`
- `/mnt/Jannik-Cloud-Volume-01/authentik/templates/`
- `/mnt/Jannik-Cloud-Volume-01/authentik/certs/`
