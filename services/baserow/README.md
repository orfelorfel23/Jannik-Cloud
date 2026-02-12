# Baserow - Database & No-Code Platform

## Overview
Baserow is an open-source database platform and no-code backend that allows you to build web applications without coding.

## Configuration
- **Domain**: https://br.orfel.de
- **Internal Port**: 11006
- **Database**: PostgreSQL 15
- **Cache**: Redis 7

## Features
- Spreadsheet-like interface
- Multiple table relationships
- Custom fields and views
- Gallery, calendar, and timeline views
- API and webhooks
- Form sharing
- User authentication

## First Run
1. Navigate to https://br.orfel.de
2. Create an account
3. Start building databases and apps

## Data Storage
- Application data: /mnt/Jannik-Cloud-Volume-01/baserow
- Database: /mnt/Jannik-Cloud-Volume-01/baserow/postgres
- Cache: /mnt/Jannik-Cloud-Volume-01/baserow/redis

## API
Access the Baserow API programmatically for automation.

## Logs
```bash
docker logs baserow
```
