# Syncthing

Continuous file synchronization program. Used here to sync music for Navidrome.

- **Ports**:
  - Web UI: 127.0.0.1:7962 -> 8384
  - Sync Traffic: 22000 TCP/UDP (Exposed to host, but will fall back to Relays if firewall blocks it)
  - Local Discovery: 21027 UDP
- **Volumes**:
  - `/mnt/Jannik-Cloud-Volume-01/syncthing/config` (App data)
  - `/mnt/Jannik-Cloud-Volume-01/navidrome/music` (Mounted as `/var/syncthing/Music`)

## Access
Web UI available at `sync.orfel.de`.
Ensure you set a GUI password immediately upon first login.
