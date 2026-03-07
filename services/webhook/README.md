# Webhook — GitHub Webhook Receiver

## Subdomain
`webhook.orfel.de`

## Port Mapping
`9500:9000`

## Webhook Endpoints

| Hook ID | URL | Trigger |
|---------|-----|---------|
| `rebuild-linus` | `https://webhook.orfel.de/hooks/rebuild-linus` | Rebuilds the linus container (lsound website) |
| `deploy-cloud` | `https://webhook.orfel.de/hooks/deploy-cloud` | Runs the full `deploy_script.sh` |

## GitHub Configuration

1. Go to the repo's **Settings → Webhooks → Add webhook**
2. **Payload URL**: Use the URL from the table above
3. **Content type**: `application/json`
4. **Secret**: The `WEBHOOK_SECRET` value from `.env`
5. **Events**: Select "Just the push event"

## Adding New Webhooks

1. Add a new entry to `hooks.json`
2. Create a corresponding script in `scripts/`
3. Re-deploy to apply changes

## Persistent Data
`/mnt/Jannik-Cloud-Volume-01/webhook/`
