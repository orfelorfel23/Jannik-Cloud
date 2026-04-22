# Baserow — No-Code Database

## Subdomain
`br.orfel.de`

## Port Mapping
`2273:80`

## Dependencies
- PostgreSQL (DB: `baserow_db`)

## Persistent Data
`/mnt/Jannik-Cloud-Volume-01/baserow/`

## Backup & Restore

### Auto-Backup
This service is integrated into the master deploy script. Every time `deploy_script.sh` runs, it calls `service.backup` which:
1. Dumps the `baserow_db` PostgreSQL database.
2. Archives the uploads/pictures volume.
3. Keeps only the last 5 backups in `~/baserow_backups/`.

### Manual Restore
To restore data (e.g., on a new server):
1. Ensure the new server has run `deploy_script.sh` at least once.
2. Copy your `.sql` and `.tar.gz` backup files to the new server.
3. Run the restore script:
   ```bash
   sudo bash restore-baserow.sh <path_to_sql> <path_to_tar_gz>
   ```

