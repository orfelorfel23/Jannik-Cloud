# Outline Wiki

Outline is a modern wiki and knowledge base for teams.

## Service Information

- **URL**: https://outline.orfel.de
- **Internal Port**: 3000
- **Data Location**: /mnt/Jannik-Cloud-Volume-01/outline

## Components

- Outline application
- PostgreSQL database
- Redis cache

## Environment Variables

Generated automatically by `generate-env.sh`:
- `SECRET_KEY`: Application secret key
- `UTILS_SECRET`: Utilities secret key
- `POSTGRES_USER`: Database username
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name

## Manual Deployment

```bash
# Generate environment file
./generate-env.sh

# Start service
docker compose up -d

# View logs
docker compose logs -f

# Stop service
docker compose down
```

## First-Time Setup

After deployment, visit https://outline.orfel.de to complete the initial setup.
