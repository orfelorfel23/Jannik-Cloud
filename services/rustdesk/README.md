# RustDesk Server — Self-Hosted Remote Desktop

## Subdomain
`rust.orfel.de` — Web admin UI only

## Port Mapping
- `127.0.0.1:7878:21114` — Web admin API (behind Caddy)
- `21115:21115/tcp` — NAT type test
- `21116:21116/tcp+udp` — ID registration & heartbeat
- `21117:21117/tcp` — Relay traffic
- `21118:21118/tcp` — WebSocket (optional)
- `21119:21119/tcp` — WebSocket (optional)

## Containers
- `rustdesk` — hbbs (ID/rendezvous server)
- `rustdesk-relay` — hbbr (relay server)

## ⚠️ Required Firewall Configuration

The signal and relay ports **must be opened manually** in the server firewall. The deploy script does NOT configure these.

### Using ufw

```bash
sudo ufw allow 21115/tcp comment "RustDesk NAT type test"
sudo ufw allow 21116/tcp comment "RustDesk ID registration (TCP)"
sudo ufw allow 21116/udp comment "RustDesk ID registration (UDP)"
sudo ufw allow 21117/tcp comment "RustDesk relay traffic"
sudo ufw allow 21118/tcp comment "RustDesk WebSocket (optional)"
sudo ufw allow 21119/tcp comment "RustDesk WebSocket (optional)"
sudo ufw reload
```

### Using iptables (alternative)

```bash
sudo iptables -A INPUT -p tcp --dport 21115 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 21116 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 21116 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 21117 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 21118 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 21119 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

## Port Explanation

| Port | Protocol | Purpose |
|------|----------|---------|
| 21114 | TCP | Web console / API (proxied via Caddy) |
| 21115 | TCP | NAT type test — determines client connectivity |
| 21116 | TCP+UDP | ID server — client registration and heartbeat |
| 21117 | TCP | Relay server — relays traffic when direct P2P fails |
| 21118 | TCP | WebSocket for web client (optional) |
| 21119 | TCP | WebSocket for web client (optional) |

## Configuring RustDesk Clients

1. Open RustDesk on the client device
2. Go to **Settings → Network**
3. Configure the following fields:

| Field | Value |
|-------|-------|
| **ID Server** | `orfel.de` |
| **Relay Server** | `orfel.de` |
| **API Server** | `https://rust.orfel.de` |

4. The **Key** will be auto-generated on first server start at `/mnt/Jannik-Cloud-Volume-01/rustdesk/id_ed25519.pub`
5. Copy the public key content and paste it into the **Key** field on each client

### Getting the public key

```bash
cat /mnt/Jannik-Cloud-Volume-01/rustdesk/id_ed25519.pub
```

## Persistent Data
`/mnt/Jannik-Cloud-Volume-01/rustdesk/`
