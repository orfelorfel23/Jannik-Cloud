# NextCloud - File Hosting & Collaboration

## Overview
NextCloud is a suite for file hosting, synchronization, and communication services including email, calendars, and more.

## Configuration
- **Domain**: https://nextcloud.orfel.de
- **Internal Port**: 11004
- **Admin User**: Jannik
- **Database**: PostgreSQL 15
- **Cache**: Redis 7

## Features
- File storage and synchronization
- Calendar and contacts management
- Talk (video conferencing)
- Collaborative document editing (with plugins)
- Notes and bookmarks
- Phone backup
- Dashboard

## First Run
1. Navigate to https://nextcloud.orfel.de
2. Admin account: Jannik
3. Create additional users or sync with LDAP/OIDC

## Data Storage
- User files: /mnt/Jannik-Cloud-Volume-01/nextcloud/data
- Database: /mnt/Jannik-Cloud-Volume-01/nextcloud/postgres
- Cache: /mnt/Jannik-Cloud-Volume-01/nextcloud/redis

## Desktop/Mobile Apps
Download apps for Windows, macOS, iOS, and Android.

## Logs
```bash
docker logs nextcloud
docker logs nextcloud-postgres
docker logs nextcloud-redis
```
