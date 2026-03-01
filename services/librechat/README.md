# LibreChat — AI Chat Interface

## Subdomain
`chat.orfel.de`

## Port Mapping
`2428:3080`

## Dependencies
- PostgreSQL (DB: `librechat_db`)
- Redis

## Setup
1. Run `bash generate-env.sh`
2. Replace `LITELLM_API_KEY=PLACEHOLDER` with the key from your LiteLLM instance
3. Re-encrypt and commit `.env.age`

## Persistent Data
- `/mnt/Jannik-Cloud-Volume-01/librechat/images`
- `/mnt/Jannik-Cloud-Volume-01/librechat/logs`
