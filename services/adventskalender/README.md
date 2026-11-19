# Adventskalender (`adventskalender.orfel.de`)

- **Image:** `git.orfel.de/jannik/adventskalender:latest`
- **Container / Port:** `adventskalender` (intern `3000`, Host-Binding `127.0.0.1:238:3000`)
- **Caddy-Route:** `https://adventskalender.orfel.de` -> `reverse_proxy adventskalender:3000`
- **Live-Override-Volume:** `/mnt/Jannik-Cloud-Volume-01/adventskalender` -> `/app/content-override` (`ro`)
- **Secrets:** `.env.age` (mit `keys/age-public-key.txt` verschlüsselt; wird beim Deploy automatisch als `.env` entschlüsselt)
