# TokenWatch Deployment for Jannik-Cloud

To deploy TokenWatch to your Jannik-Cloud, follow these steps:

1. Push the `TokenWatch` repository to GitHub (`github.com/orfelorfel23/TokenWatch`).
2. The included GitHub Action (`.github/workflows/docker.yml`) will automatically build the Docker image and push it to `ghcr.io/orfelorfel23/tokenwatch:latest`.
3. In your `Jannik-Cloud` repository, copy the contents of this `deployment-template` directory into `services/tokenwatch/`.
4. Run `bash generate-env.sh` inside `services/tokenwatch/` on your server to generate the database credentials.
5. Commit `.env.age`, `docker-compose.yml`, `tokenwatch.caddy`, and `service.enabled` to `Jannik-Cloud`.
6. Run `sudo bash deploy_script.sh` on the server!

**Local Sync Setup:**
On your Windows PC where Antigravity IDE runs, open the Windows Task Scheduler.
- Create a new task that runs every 30 minutes.
- Action: Start a program
- Program: `powershell`
- Arguments: `-ExecutionPolicy Bypass -File "C:\GitHub\TokenWatch\Push-AntigravityQuota.ps1"`

Before running it for production, edit `C:\GitHub\TokenWatch\tokenwatch-sync.js` locally and change the `url` to point to your new cloud endpoint:
`const url = 'https://tokenwatch.orfel.de/api/webhook/antigravity';`
