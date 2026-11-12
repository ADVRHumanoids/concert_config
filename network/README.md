# Concert network setup

## Router setup

- IP: `10.24.10.1`
- Hostname: `concert-robot` (TBD)
- User: admin
- Password: you should know...
- DHCP server enabled, with the following static IP addresses (MACs TBD)

| PC       | User       | IPv4-Address | MAC-Address |
|----------|------------|--------------|-------------|
| embedded | `embedded` | 10.24.10.100 | TBD         |
| vision   | `concert`  | 10.24.10.101 | TBD         |
| control  | `concert`  | 10.24.10.102 | TBD         |

 - Port mapping (DNAT) is enabled, as in `milesight/port_forwarding.png`:

| Name             | Protocol | External port | Internal               |
|------------------|----------|---------------|------------------------|
| ssh-control      | TCP      | 22            | `10.24.10.102:22`      |
| ssh-embedded     | TCP      | 23            | `10.24.10.100:22`      |
| wg-control       | UDP      | 51820         | `10.24.10.102:51820`   |
| ssh-perception   | TCP      | 24            | `10.24.10.101:22`      |
| xbot2-gui-server | TCP, UDP | 8080          | `10.24.10.102:8080`    |
| influxdb         | TCP      | 8086          | `10.24.10.102:8086`    |
| victorialogs     | TCP      | 9428          | `10.24.10.102:9428`    |
