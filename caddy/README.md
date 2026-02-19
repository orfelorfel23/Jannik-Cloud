# Caddy Reverse Proxy

Caddy serves as the main reverse proxy and handles all HTTPS/SSL certificates automatically.

## Configuration

- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Let's Encrypt Email**: jannik.mueller.jannik+git@googlemail.com
- **Data Location**: /mnt/Jannik-Cloud-Volume-01/caddy

## Caddyfile

The Caddyfile maps each subdomain to its respective Docker container and internal port.

## Management

### Reload configuration
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### View logs
```bash
docker compose logs -f
```

### Check certificate status
```bash
docker exec caddy caddy list-certificates
```

## Adding a New Service

Add to Caddyfile:
```
newservice.orfel.de {
    reverse_proxy container-name:port
}
```

Then reload:
```bash
docker compose restart
```
