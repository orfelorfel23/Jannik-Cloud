# Deezer Downloader

## Subdomain
`deezer.orfel.de`

## Port Mapping
`127.0.0.1:673:6123`

## ⚠️ Required: Deezer ARL Cookie

The `DEEZER_ARL` environment variable **must be set manually** after deployment. It is a placeholder by default.

### How to obtain your Deezer ARL cookie

1. Open a web browser and log in to [deezer.com](https://www.deezer.com)
2. Open Developer Tools (`F12` or `Ctrl+Shift+I`)
3. Go to the **Application** tab (Chrome) or **Storage** tab (Firefox)
4. Expand **Cookies** → click on `https://www.deezer.com`
5. Find the cookie named `arl`
6. Copy the **Value** (it's a long hex string)
7. Edit the `.env` file on the server:

```bash
nano /opt/Jannik-Cloud/services/deezer/.env
```

8. Replace `DEEZER_ARL=PLACEHOLDER` with your actual ARL value:

```
DEEZER_ARL=your_actual_arl_cookie_value_here
```

9. Re-encrypt and restart:

```bash
cd /opt/Jannik-Cloud/services/deezer
age -r "$(cat /opt/Jannik-Cloud/keys/age-public-key.txt)" -o .env.age .env
docker compose restart
```

> **Note**: ARL cookies expire periodically. If downloads stop working, repeat the steps above with a fresh ARL.

## Persistent Data
- `/mnt/Jannik-Cloud-Volume-01/deezer/downloads/` — downloaded music files
- `/mnt/Jannik-Cloud-Volume-01/deezer/config/` — configuration
