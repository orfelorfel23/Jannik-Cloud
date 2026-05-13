# LibreChat — AI Chat Interface

## Subdomain
`chat.orfel.de`

## Port Mapping
`2428:3080`

## Dependencies
- PostgreSQL (DB: `librechat_db`)
- Redis
- LiteLLM (internal: `http://litellm:4000`)

## Setup
1. Deploy LiteLLM first and create a Virtual API Key in its admin UI (`https://llm.orfel.de`)
2. Run `bash generate-env.sh`
3. Edit `.env` and replace `LITELLM_API_KEY=PLACEHOLDER` with the key from step 1
4. Re-encrypt: `age -r "$(cat ../../keys/age-public-key.txt)" -o .env.age .env`
5. Commit `.env.age` and redeploy — LibreChat will auto-configure the LiteLLM endpoint

## Config
`librechat.yaml` is committed to the repo and mounted read-only into the container.
The `${LITELLM_API_KEY}` placeholder is interpolated at runtime from the container environment.
To add more models, edit `librechat.yaml` and redeploy.

## Persistent Data
- `/mnt/Jannik-Cloud-Volume-01/librechat/images`
- `/mnt/Jannik-Cloud-Volume-01/librechat/logs`
