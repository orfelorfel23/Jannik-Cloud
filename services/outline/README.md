# Outline — Wiki & Knowledge Base

## Subdomain
`outline.orfel.de`

## Port Mapping
`688:3000`

## Dependencies
- PostgreSQL (DB: `outline_db`)
- Redis

## Setup
1. Run `bash generate-env.sh`
2. Replace `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env` with real values
3. Re-encrypt: `age -r "$(cat ../../keys/age-public-key.txt)" -o .env.age .env`
4. Commit `.env.age`

## Persistent Data
`/mnt/Jannik-Cloud-Volume-01/outline/`
