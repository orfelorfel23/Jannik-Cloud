# Portainer - Docker Management UI

## Overview
Portainer is a lightweight Docker management UI. Manage your containers, images, networks, and volumes from a web interface.

## Configuration
- **Domain**: https://port.orfel.de
- **Internal Port**: 11002
- **Admin User**: admin (initial)
- **Admin Password**: Check .env file

## Features
- Container management
- Image management
- Docker Compose stack management
- Volume and network management
- Registry management
- Environmental variable management

## First Login
1. Navigate to https://port.orfel.de
2. Create admin account with password from .env
3. Connect to local Docker socket

## Data Storage
- Database: /mnt/Jannik-Cloud-Volume-01/portainer

## Docker Socket Access
Portainer connects to the Docker daemon via:
- `/var/run/docker.sock` (read-only)

## Logs
```bash
docker logs portainer
```

## Backup
Portainer data is stored in the volume. Regular backups recommended.
