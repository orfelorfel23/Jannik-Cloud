# Outline - Knowledge Base & Wiki

## Overview
Outline is a team wiki and knowledge base designed for your team to collaborate, document, and share knowledge. It's self-hosted and provides a modern alternative to Confluence.

## Configuration
- **Domain**: https://outline.orfel.de
- **Internal Port**: 11000
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **User**: Jannik

## Features
- Real-time collaborative editing
- Full-text search
- Rich markdown support
- Team workspaces
- API for integrations

## Data Storage
- Database: /mnt/Jannik-Cloud-Volume-01/outline/postgres
- Cache: /mnt/Jannik-Cloud-Volume-01/outline/redis
- General: /mnt/Jannik-Cloud-Volume-01/outline

## First Run
1. Navigate to https://outline.orfel.de
2. Configure OIDC authentication (see .env)
3. Create your first workspace

## Logs
```bash
docker logs outline
docker logs outline-postgres
docker logs outline-redis
```

## Backup
Backup the PostgreSQL database:
```bash
docker exec outline-postgres pg_dump -U outline_user outline > backup.sql
```

## Restore
```bash
docker exec -i outline-postgres psql -U outline_user outline < backup.sql
```
