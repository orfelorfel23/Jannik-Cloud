# Gitea - Git Service

## Overview
Gitea is a self-hosted Git service. Host your own git repositories with a lightweight web interface.

## Configuration
- **Domain**: https://git.orfel.de
- **Internal Port**: 11011
- **Database**: PostgreSQL 15
- **Admin User**: Jannik

## Features
- Git repository hosting
- Web interface for repository management
- Issue tracking
- Pull requests and code review
- Webhooks and CI/CD integration
- OAuth2 authentication
- User and organization management

## First Run
1. Navigate to https://git.orfel.de
2. Gitea will prompt for initial setup
3. Create an admin account (recommended: Jannik)

## Data Storage
- Repositories and data: /mnt/Jannik-Cloud-Volume-01/gitea
- Database: /mnt/Jannik-Cloud-Volume-01/gitea/postgres

## Git Clone
```bash
git clone https://git.orfel.de/username/repo-name.git
```

## SSH Access
Configure SSH access for passwordless git operations.

## Integration with N8N and Webhook
Connect repositories to N8N workflows via webhooks.

## Logs
```bash
docker logs gitea
docker logs gitea-postgres
```

## Backup
```bash
docker exec gitea-postgres pg_dump -U gitea_user gitea > gitea-backup.sql
```
