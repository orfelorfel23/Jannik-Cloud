# Vaultwarden - Password Manager

## Overview
Vaultwarden is a self-hosted password manager and vault, compatible with Bitwarden. Securely store and manage passwords.

## Configuration
- **Domain**: https://pw.orfel.de
- **Internal Port**: 11007
- **Signups**: Enabled
- **Storage**: /mnt/Jannik-Cloud-Volume-01/vaultwarden

## Features
- Password vault
- Password generator
- Browser extensions (Chrome, Firefox, etc.)
- Mobile apps for iOS/Android
- Organization and team management
- Encrypted sharing

## First Run
1. Navigate to https://pw.orfel.de
2. Create an account
3. Install browser extension
4. Start saving passwords

## Bitwarden Compatibility
Access via Bitwarden apps by setting custom vault URL to `https://pw.orfel.de`

## Data Storage
- Database and vault: /mnt/Jannik-Cloud-Volume-01/vaultwarden

## Logs
```bash
docker logs vaultwarden
tail -f /mnt/Jannik-Cloud-Volume-01/vaultwarden/vaultwarden.log
```

## Backup
Regular backups of /mnt/Jannik-Cloud-Volume-01/vaultwarden recommended
