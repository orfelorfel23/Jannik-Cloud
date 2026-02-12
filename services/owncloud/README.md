# OwnCloud - File Sync & Share

## Overview
OwnCloud is an open-source file hosting service that allows you to store files, share them, and synchronize them across devices.

## Configuration
- **Domain**: https://owncloud.orfel.de
- **Internal Port**: 11003
- **Admin User**: Jannik
- **Database**: PostgreSQL 15

## Features
- File synchronization and sharing
- Web interface and desktop/mobile apps
- Collaborative office editing (with plugins)
- Full-text search
- Versioning and undelete
- Encryption at rest

## First Run
1. Navigate to https://owncloud.orfel.de
2. Admin account: Jannik
3. Configure additional users as needed

## Data Storage
- User files: /mnt/Jannik-Cloud-Volume-01/owncloud/data
- Database: /mnt/Jannik-Cloud-Volume-01/owncloud/postgres

## Desktop/Mobile Sync
Download the OwnCloud client and sync your files to local devices.

## Logs
```bash
docker logs owncloud
```
