# MediaWiki - Wiki Platform

## Overview
MediaWiki is the free software wiki engine used by Wikipedia. Host your own knowledge base and collaborate with others.

## Configuration
- **Domain**: https://wiki.orfel.de
- **Internal Port**: 11005
- **Admin User**: Jannik
- **Database**: PostgreSQL 15
- **Site Name**: Jannik's Wiki

## Features
- Full wiki editing with markup
- Page history and versioning
- User management
- Templates and categories
- Full-text search
- Upload and embed media

## First Run
1. Navigate to https://wiki.orfel.de
2. Admin account: Jannik
3. Customize site settings

## Data Storage
- Media files: /mnt/Jannik-Cloud-Volume-01/mediawiki
- Database: /mnt/Jannik-Cloud-Volume-01/mediawiki/postgres

## Logs
```bash
docker logs mediawiki
```

## Backup
```bash
docker exec mediawiki-postgres pg_dump -U mediawiki_user mediawiki > backup.sql
```
