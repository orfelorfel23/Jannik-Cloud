# Repository Structure

```
Jannik-Cloud/
├── .git/                              # Git repository
├── .gitignore                         # Git ignore rules
├── README.md                          # Main documentation
├── DEPLOYMENT.md                      # Deployment guide
├── STRUCTURE.md                       # This file
├── deploy_script.sh                   # Main deployment script (executable)
│
├── caddy/                             # Reverse proxy service
│   ├── Caddyfile                      # Caddy configuration
│   ├── docker-compose.yml             # Caddy Docker setup
│   └── README.md                      # Caddy documentation
│
├── scripts/                           # Utility scripts
│   ├── check-status.sh                # Check services status
│   ├── decrypt-secrets.sh             # Decrypt all .env.age files
│   ├── encrypt-all-env.sh             # Encrypt all .env files
│   ├── generate-age-key.sh            # Generate AGE key pair
│   ├── generate-password.sh           # Generate secure password
│   └── show-credentials.sh            # Display all credentials
│
└── services/                          # All service directories
    │
    ├── baserow/                       # Baserow (No-code database)
    │   ├── docker-compose.yml         # Service configuration
    │   ├── generate-env.sh            # Environment generator
    │   ├── .env                       # Environment file (not in git)
    │   ├── .env.age                   # Encrypted environment (in git)
    │   └── README.md                  # Service documentation
    │
    ├── gitea/                         # Gitea (Git service)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── homeassistant/                 # Home Assistant
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── librechat/                     # LibreChat (ChatGPT alternative)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── litellm/                       # LiteLLM (LLM proxy)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── mediawiki/                     # MediaWiki
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── n8n/                           # n8n (Workflow automation)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── nextcloud/                     # Nextcloud
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── ntfy/                          # ntfy (Notifications)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── outline/                       # Outline (Wiki)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── owncloud/                      # ownCloud
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── portainer/                     # Portainer (Docker UI)
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    ├── stirling-pdf/                  # Stirling PDF
    │   ├── docker-compose.yml
    │   ├── generate-env.sh
    │   ├── .env
    │   ├── .env.age
    │   └── README.md
    │
    └── vaultwarden/                   # Vaultwarden (Password manager)
        ├── docker-compose.yml
        ├── generate-env.sh
        ├── .env
        ├── .env.age
        └── README.md
```

## File Types

### Configuration Files
- `docker-compose.yml` - Docker Compose configuration (no version attribute)
- `Caddyfile` - Caddy reverse proxy configuration
- `.env` - Environment variables (plaintext, not committed to git)
- `.env.age` - Encrypted environment variables (committed to git)

### Scripts
- `deploy_script.sh` - Main deployment automation
- `generate-env.sh` - Per-service environment file generator
- `*.sh` in scripts/ - Various utility scripts

### Documentation
- `README.md` - Service or section documentation
- `DEPLOYMENT.md` - Deployment instructions
- `STRUCTURE.md` - This file

## Data Locations

All persistent data is stored on the mounted volume:

```
/mnt/Jannik-Cloud-Volume-01/
├── caddy/
│   ├── data/              # SSL certificates
│   └── config/            # Caddy configuration
├── baserow/
│   ├── data/
│   ├── postgres/
│   └── redis/
├── gitea/
│   ├── data/
│   └── postgres/
├── homeassistant/
│   └── config/
├── librechat/
│   ├── data/
│   └── mongodb/
├── litellm/
│   ├── config/
│   └── postgres/
├── mediawiki/
│   ├── images/
│   ├── data/
│   └── mysql/
├── n8n/
│   └── data/
├── nextcloud/
│   ├── html/
│   ├── data/
│   ├── mysql/
│   └── redis/
├── ntfy/
│   ├── cache/
│   └── data/
├── outline/
│   ├── data/
│   ├── postgres/
│   └── redis/
├── owncloud/
│   ├── data/
│   ├── mysql/
│   └── redis/
├── portainer/
│   └── data/
├── stirling-pdf/
│   ├── data/
│   └── config/
└── vaultwarden/
    └── data/
```

## Key Locations

AGE encryption keys are stored separately:

```
/opt/Jannik-Cloud/keys/
└── age-key.txt            # Private key (mode 600)
```

## Docker Network

All services connect to a single Docker bridge network:
- Network name: `jannik-cloud-net`
- Only Caddy exposes ports to host (80, 443)
- All other services use internal ports

## Execution Permissions

These files should be executable:
- `deploy_script.sh`
- `scripts/*.sh`
- `services/*/generate-env.sh`
