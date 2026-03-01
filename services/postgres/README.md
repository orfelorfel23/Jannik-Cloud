# PostgreSQL — Shared Database

Single shared PostgreSQL instance used by multiple services. The deploy script automatically creates a dedicated database and user for each service.

## Services Using PostgreSQL

Outline, Gitea, N8N, Baserow, LibreChat, MediaWiki, Vaultwarden, Nextcloud, LiteLLM

## Persistent Data

`/mnt/Jannik-Cloud-Volume-01/postgres/`

## Database Provisioning

The deploy script reads `NEEDS_POSTGRES=true` from each service's `.env` and creates:
- Database: `<service>_db`
- User: `<service>_user`
- Password: from `DB_PASSWORD` in the service `.env`

All operations are idempotent (`IF NOT EXISTS`).
