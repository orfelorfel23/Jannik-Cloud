# ILIAS — Learning Management System

## Subdomain
`ilias.orfel.de`

## Port Mapping
`127.0.0.1:45427:80`

## Containers
- `ilias` — ILIAS web application
- `ilias-mysql` — Dedicated MySQL 8 instance (not shared PostgreSQL)

## Database
Uses its own MySQL instance — does NOT use the shared PostgreSQL.

## Persistent Data
- `/mnt/Jannik-Cloud-Volume-01/ilias/mysql/` — MySQL data
- `/mnt/Jannik-Cloud-Volume-01/ilias/data/` — ILIAS application data
- `/mnt/Jannik-Cloud-Volume-01/ilias/iliasdata/` — ILIAS user data
