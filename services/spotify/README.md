# Spotify Plailist

## Subdomain
- `spotify.orfel.de`

## Port Mapping
`1337:80`

## Source Repository
https://github.com/H4f3rk3ks/spotify-plailist

## How It Works
- Uses a custom multi-stage Dockerfile
- **Stage 1**: Clones the source repo, runs `npm ci && npm run build`
- **Stage 2**: Serves the built static files via Nginx
- On each deploy, the container is rebuilt with `--no-cache` to pull the latest code

## Auto-Update via Webhook
A webhook at `webhook.orfel.de` triggers a rebuild when the source repo is updated.

## Persistent Data
`/mnt/Jannik-Cloud-Volume-01/spotify/`
