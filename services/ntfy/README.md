# Ntfy - Push notifications

## Overview
Ntfy is a simple pub/sub notification service. Send desktop/mobile push notifications from anywhere with just a HTTP PUT or POST.

## Configuration
- **Domain**: https://ntfy.orfel.de
- **Internal Port**: 11009
- **Base URL**: https://ntfy.orfel.de

## Features
- Simple HTTP-based API
- Desktop and mobile notifications
- Topic-based messaging
- Email notifications
- Android app
- Scheduled messages

## Basic Usage
Send a notification:
```bash
curl -X POST https://ntfy.orfel.de/my-topic \
  -H "Title: Hello" \
  -d "This is a notification"
```

Subscribe to a topic:
- Open https://ntfy.orfel.de/my-topic in browser
- Or use the Android app

## Data Storage
- Cache: /mnt/Jannik-Cloud-Volume-01/ntfy

## Logs
```bash
docker logs ntfy
```

## Integration Examples
- GitHub Actions: Send build notifications
- Home Assistant: Send automation alerts
- Monitoring: Alert on system issues
