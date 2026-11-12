# CONCERT Robot Configuration

Configuration files for the CONCERT robot: shell profiles, Docker containers, WireGuard VPN, CycloneDDS, EtherCAT, and the GUI launcher.

---

## Network overview

The robot network is a dedicated LAN (`10.24.10.0/24`) managed by the onboard router. Three PCs live on this LAN:

| Host | Role | User | IP |
|---|---|---|---|
| embedded | Embedded PC | `embedded` | `10.24.10.100` |
| vision | Vision / perception PC (Jetson) | `concert` | `10.24.10.101` |
| control | Control PC | `concert` | `10.24.10.102` |
| `concert-robot` (TBD) | Router / gateway | `admin` | `10.24.10.1` |

*Note:* the router's DHCP server is **enabled**. The IPs in the table above are obtained by
pinning each machine's MAC address to a specific static IP from the router settings
(see [network/README.md](network/README.md)).

*Note:* you must not connect any of the router's LAN ports to the corporate network.

Because the robot's RJ45 port is internally wired to the router's WAN port, accessing the robot local network from outside (WAN)
is not directly possible. To circumvent this limitation, a WireGuard-based VPN is run by the control PC.
The router then forwards WireGuard (UDP `51820`) to the control PC, allowing remote VPN access into the robot LAN.

The router also allows SSH access to all robot PCs from the WAN thanks to the following forwarding rules
```
concert-robot:22 --> control:22(sshd)
concert-robot:23 --> embedded:22(sshd)
concert-robot:24 --> vision:22(sshd)
```

Therefore, it is possible to SSH into the embedded PC from the WAN with
```bash
$ ssh -p 23 embedded@concert-robot
```

The router also forwards the XBot2 GUI server (`8080`), InfluxDB (`8086`) and VictoriaLogs (`9428`)
to the control PC; the full table is in [network/README.md](network/README.md).

Connecting to the robot VPN is explained below in this document.

---

## A · Setting up the robot PCs
This section is meant for robot maintainers, to help them with the robot commissioning operations.

### 1. Clone this repo

Clone the repository to the same path on all PCs:

```bash
$ git clone <repo-url> <path/to/concert_config>
```

### 2. Source the host profile

Each PC has a host-side shell profile that sets environment variables, SSH aliases, and sources the Docker helper scripts. Add the appropriate line to `~/.bashrc` so it is loaded on every login:

- **control:**
  ```bash
  $ source <path/to/concert_config>/host/control_profile.bash
  ```
  Sets `ROS_IP=10.24.10.102`, `RENDER_GID` (for VA hardware acceleration), the concert launcher output folder, and sources the `concert-noble-ros2` Docker helper (which provides the `concert` shell function — see below).

- **embedded:**
  ```bash
  $ source <path/to/concert_config>/host/embedded_profile.bash
  ```
  Sets `ROS_IP=10.24.10.100`, `KERNEL_VER`, the concert launcher output folder, and sources the `concert-noble-ros2-xeno` Docker helper.

- **vision:**
  ```bash
  $ source <path/to/concert_config>/host/perception_profile.bash
  ```
  Sets `ROS_IP=10.24.10.101`, the concert launcher output folder, and sources the `concert-noble-ros2-jetpack-r36.5` Docker helper.

### 3. Start a Docker container with the `concert` alias

Sourcing the host profile above makes the `concert` shell function available. It takes a Docker Compose service name as its argument, starts the container if it is not already running, and opens an interactive shell inside it. The service name is usually `dev`:

```bash
$ concert dev
```

The function runs `docker compose up <service> -d --no-recreate` followed by `docker compose exec <service> bash`, and also calls `xhost +local:root` to allow GUI applications inside the container.
On the control PC, `dev-intel-va` and `dev-nvidia` start the same container with Intel VA or NVIDIA GPU access.

### 4. Environment inside the container

When a shell is opened inside a container, the corresponding Docker profile is sourced automatically to configure the ROS 2 middleware environment:

| Container | Profile |
|---|---|
| `concert-noble-ros2` (control) | `docker/control_profile_docker.bash` |
| `concert-noble-ros2-xeno` (embedded) | `docker/embedded_profile_docker.bash` |
| `concert-noble-ros2-jetpack-r36.5` (vision) | `docker/perception_profile_docker.bash` |

All three profiles source `docker/generic_profile_docker.bash`, which sets `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` and the concert launcher's default config (`gui/launcher_config.yaml`). Each then sets the appropriate `CYCLONEDDS_URI` pointing to the corresponding CycloneDDS XML config under `network/cyclone/`. The embedded profile additionally sets `ECAT_MASTER_CONFIG` and the `ecat_master` / `ecat_master_gdb` aliases for the EtherCAT master.

### 5. WireGuard server (control only)

The WireGuard VPN server must be set up once on the control PC before any remote client can connect. Follow the full instructions in [network/wg/README.md](network/wg/README.md) to generate the server keypair, write `/etc/wireguard/wg0.conf`, and bring up the `wg-quick@wg0` systemd service. Any static peer (e.g. the pilot PC) must have its public key added to `wg0.conf` before the service is started.

### 6. Host monitor services

The diagnostics host monitors run as systemd services, one per PC; see [services/README.md](services/README.md).

---

## B · Setting up a remote client / pilot

### 1. Clone this repo and source the client profile

On the remote machine, clone the repository and add the client profile to `~/.bashrc`:

```bash
$ source <path/to/concert_config>/host/client_profile.bash
```

This profile sets up:
- SSH aliases `ssh_control`, `ssh_embedded` and `ssh_vision` for quick access to the robot PCs.
- `ROS_DOMAIN_ID=46` and `ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST` to isolate the client's ROS 2 graph from any local network traffic.
- The `concert` shell function (via `docker/concert-noble-ros2/setup.sh`) to enter the client-side ROS 2 container.
- Helper functions `concert_connect_wg`, `concert_connect_zenoh`, and `concert_connect` (see below).

### 2. Connect to the robot

The `concert_connect` function performs the full connection sequence in one step:

```bash
$ concert_connect          # connect VPN + start Zenoh bridge
$ concert_connect down     # disconnect VPN
```

Internally it runs two steps, which can also be invoked independently:

1. **`concert_connect_wg`** — calls `network/wg/connect-wg.bash` to establish a WireGuard tunnel into the robot LAN. On first run it generates a local keypair under `~/.wireguard/` and registers a dynamic peer on the control PC. You will be prompted once for the remote machine password. The tunnel gives the client full IP-level access to the robot LAN (`10.24.10.0/24`) and the VPN subnet (`10.0.0.0/24`).

2. **`concert_connect_zenoh`** — starts the `zenoh_bridge_client` container, which connects to the `zenoh_bridge_server` running on the control PC over the WireGuard tunnel. This bridges ROS 2 topics across the link without relying on DDS multicast, which does not work over a routed VPN.

### 3. Zenoh-over-WireGuard architecture

Direct ROS 2 / DDS discovery relies on multicast, which is unavailable across a routed WireGuard tunnel. Instead, a pair of Zenoh bridges are used to forward ROS 2 traffic over a unicast TCP connection:

```
  [ Remote client ]                          [ control  10.24.10.102, VPN 10.0.0.1 ]
  ┌───────────────────────────────┐          ┌───────────────────────────────────┐
  │ ROS 2 (CycloneDDS, :localhost)│          │  ROS 2 (CycloneDDS, robot LAN)    │
  │          ↕                    │          │          ↕                        │
  │  zenoh_bridge_client          │          │  zenoh_bridge_server              │
  │  (eclipse/zenoh-bridge-ros2dds│          │  (eclipse/zenoh-bridge-ros2dds)   │
  │   -e tcp/10.0.0.1:7447)       │          │   listens on 10.0.0.1:7447        │
  └───────────────┬───────────────┘          └──────────────▲────────────────────┘
                  │        WireGuard tunnel (TCP/7447)       │
                  └──────────────────────────────────────────┘
```

- **`zenoh_bridge_server`** runs on the control PC as part of the `concert-noble-ros2` Docker stack. It bridges the local CycloneDDS network (using `network/cyclone/cyclonedds-control.xml`) to a Zenoh endpoint that listens on the control PC's VPN address, port `7447`.
- **`zenoh_bridge_client`** runs on the remote client. It connects to `10.0.0.1:7447` through the WireGuard tunnel and re-exposes the bridged topics as a local ROS 2 network. `ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST` ensures the client's ROS 2 graph stays isolated from any other local DDS traffic.

### 4. Reaching the robot over VPN

Once the VPN tunnel is up, the full robot LAN is reachable:

```bash
$ ssh_control    # → concert@control   (10.24.10.102)
$ ssh_embedded   # → embedded@embedded (10.24.10.100)
$ ssh_vision     # → concert@vision    (10.24.10.101)
```
