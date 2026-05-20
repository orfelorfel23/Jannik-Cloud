# Navidrome

Self-hosted music server and streamer.

- **Ports**: 127.0.0.1:7664 -> 4533
- **Volumes**:
  - `/mnt/Jannik-Cloud-Volume-01/navidrome/data` (Database and cache)
  - `/mnt/Jannik-Cloud-Volume-01/navidrome/music` (Music files)

## Access
Available at `music.orfel.de` (and aliases). First login will prompt for admin user creation.

## Music Uploads
Music uploads are handled independently by the `syncthing` service, which shares the music volume.
