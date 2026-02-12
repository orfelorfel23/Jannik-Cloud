# N8N - Workflow Automation

## Overview
N8N is an open-source node-based workflow automation platform. Automate tasks and integrate your services without coding.

## Configuration
- **Domain**: https://n8n.orfel.de
- **Internal Port**: 11010
- **Database**: PostgreSQL 15
- **User**: Jannik

## Features
- 400+ integrations (Slack, GitHub, Send Grid, Google Sheets, etc.)
- Visual workflow builder
- Conditional logic and splitting
- Error handling and retries
- Webhooks and triggers
- Custom nodes with JavaScript
- Team collaboration

## First Run
1. Navigate to https://n8n.orfel.de
2. Create your first user account
3. Build workflows by connecting nodes

## Data Storage
- Workflows and data: /mnt/Jannik-Cloud-Volume-01/n8n
- Database: /mnt/Jannik-Cloud-Volume-01/n8n/postgres

## Available Integrations
- Communication: Slack, Discord, Telegram, Email
- Developer: GitHub, GitLab, Gitea
- Data: Google Sheets, Airtable, PostgreSQL
- Cloud: AWS, Google Cloud, Azure
- Monitoring: Sentry, DataDog

## Logs
```bash
docker logs n8n
```

## Documentation
Full documentation at https://docs.n8n.io
