# WireGuard Setup

Remote access VPN into the concert LAN (`10.24.10.0/24`).  
The WireGuard **server** runs on the control PC (`10.24.10.102`), reachable from the WAN on UDP port `51820`
through the router `concert-robot` (hostname TBD, see `ROUTER_HOST` in `connect-wg.bash`).

Peer model:
- **Pilot PC** — static peer, always in `wg0.conf`
- **Additional clients** — added at runtime with `wg set`; non-persistent, cleared on reboot or tunnel restart

---

## 1 · Install (server and each client)

```bash
sudo apt update && sudo apt install -y wireguard
```

---

## 2 · Generate server keypair

Run on the **control PC**:

```bash
# Generate the private key only once: regenerating it invalidates every client config
sudo test -f /etc/wireguard/server.key || \
    (umask 077; wg genkey | sudo tee /etc/wireguard/server.key > /dev/null)
# Derive the public key from the private key, so the two always match
sudo sh -c 'wg pubkey < /etc/wireguard/server.key > /etc/wireguard/server.pub'
sudo chmod 644 /etc/wireguard/server.pub  # read without sudo by connect-wg.bash
sudo chmod +x /etc/wireguard              # lets non-root users reach server.pub
```

`server.key` is the only copy of the private key. `wg0.conf` loads it at startup and MUST NOT contain it.

---

## 3 · Configure the server

First, find the LAN interface name:

```bash
ip -br link   # typically eno1, enp3s0, etc.
```

Create `/etc/wireguard/wg0.conf` on the **control PC** (template: `wg0.conf`):

```ini
[Interface]
Address    = 10.0.0.1/24
ListenPort = 51820

# Private key is loaded from file. It MUST NOT be pasted here.
PostUp   = wg set %i private-key /etc/wireguard/server.key

# Route traffic into the robot LAN — 'enp5s0' is the control PC LAN interface
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o enp5s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -o enp5s0 -j MASQUERADE

# ── Static peer: Pilot PC ──────────────────────────────────────────────────
[Peer]
# pilot-pc
PublicKey  = <pilot-pc public key>
AllowedIPs = 10.0.0.2/32
```

Enable IPv4 forwarding (persist across reboots):

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl -p /etc/sysctl.d/99-wireguard.conf
```

---

## 4 · Start the server

```bash
sudo systemctl enable --now wg-quick@wg0
sudo wg show   # verify
```

The running key MUST match `server.pub`, otherwise clients get no handshake:

```bash
[ "$(sudo wg show wg0 public-key)" = "$(cat /etc/wireguard/server.pub)" ] && echo OK || echo MISMATCH
```

---

## 5 · Pilot PC client setup

Generate a keypair on the **pilot PC**:

```bash
wg genkey | tee ~/pilot.key | wg pubkey | tee ~/pilot.pub
```

Hand `~/pilot.pub` to whoever manages `wg0.conf` to fill in the static peer block above.

Create `~/wg-concert.conf` on the **pilot PC**:

```ini
[Interface]
Address    = 10.0.0.2/24
PrivateKey = <contents of ~/pilot.key>

[Peer]
PublicKey           = <contents of /etc/wireguard/server.pub on the control PC>
Endpoint            = <concert-robot router hostname or public IP>:51820
AllowedIPs          = 10.0.0.0/24, 10.24.10.0/24
PersistentKeepalive = 25
```

```bash
sudo wg-quick up ~/wg-concert.conf
```

---

## 6 · Dynamic peers (non-persistent)

Use `wg set` to register a peer at runtime without editing any config file.  
The peer is **removed automatically** when the tunnel is restarted or the machine reboots.

### Add a dynamic peer (run on the control PC)

```bash
sudo wg set wg0 peer <CLIENT_PUBKEY> allowed-ips 10.0.0.<N>/32
```

### Remove a dynamic peer manually

```bash
sudo wg set wg0 peer <CLIENT_PUBKEY> remove
```

### Client config for a dynamic peer

```ini
[Interface]
Address    = 10.0.0.<N>/24
PrivateKey = <client private key>

[Peer]
PublicKey           = <contents of /etc/wireguard/server.pub on the control PC>
Endpoint            = <concert-robot router hostname or public IP>:51820
AllowedIPs          = 10.0.0.0/24, 10.24.10.0/24
PersistentKeepalive = 25
```

---

## 7 · Dynamic peers via `connect-wg.bash`

`connect-wg.bash` automates the dynamic peer workflow (section 6) for any client machine.  
It SSHs into the control PC (through the router, port 22), picks the next free VPN address (`10.0.0.10–254`), registers the peer, writes a temporary tunnel config to `/tmp/wg-concert.conf`, and brings up the tunnel — all in one step.

### Prerequisites

Install the required tools on the **client**:

```bash
sudo apt install -y wireguard sshpass
```

SSH access to `concert@concert-robot` must be reachable from the client (either on the LAN or via a jump host).

### Connect

```bash
./connect-wg.bash
```

You will be prompted for the password of `concert@concert-robot`.  
On first run the script generates a keypair under `~/.wireguard/` (`concert.key` / `concert.pub`).  
After connecting it prints the assigned VPN IP and reachable hosts:

```
Connected as 10.0.0.10
  control   10.24.10.102  (10.0.0.1)
  embedded  10.24.10.100
  vision    10.24.10.101
```

### Disconnect

```bash
./connect-wg.bash down
```

This removes the peer from the server and tears down the local tunnel.  
The peer is also cleared automatically on server reboot or tunnel restart.

---

## 8 · Verify connectivity

```bash
# from any client
ping 10.0.0.1        # control PC VPN address
ping 10.24.10.102    # control PC LAN
ping 10.24.10.100    # embedded PC
ping 10.24.10.101    # vision PC

# on the server — show active tunnels and last handshake times
sudo wg show
```

---

## Quick reference

| Host           | LAN IP        | VPN IP    | Peer type |
|----------------|---------------|-----------|-----------|
| control        | 10.24.10.102  | 10.0.0.1  | server    |
| pilot-pc       | —             | 10.0.0.2  | static    |
| embedded       | 10.24.10.100  | —         | —         |
| vision         | 10.24.10.101  | —         | —         |
| *dynamic-N*    | —             | 10.0.0.N  | dynamic   |
