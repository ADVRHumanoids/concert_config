# Concert systemd services

## Setup

Each service runs the host monitor script of its PC as the `User=` in the unit, from the
`ExecStart=` path: the user MUST exist and this repo MUST be cloned at that path.
Run `scripts/setup_host_monitor.bash` once as that user first.

**Embedded**
```
$ sudo cp services/xbot2_host_monitor_embedded.service /etc/systemd/system/
$ sudo systemctl enable xbot2_host_monitor_embedded
$ sudo systemctl start xbot2_host_monitor_embedded
```

**Control**
```
$ sudo cp services/xbot2_host_monitor_control.service /etc/systemd/system/
$ sudo systemctl enable xbot2_host_monitor_control
$ sudo systemctl start xbot2_host_monitor_control
```

**Jetson**
```
$ sudo cp services/xbot2_host_monitor_jetson.service /etc/systemd/system/
$ sudo systemctl enable xbot2_host_monitor_jetson
$ sudo systemctl start xbot2_host_monitor_jetson
```

Check a service with `systemctl status <name>` and its output with `journalctl -u <name> -f`.
