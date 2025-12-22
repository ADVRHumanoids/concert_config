# Concert Config

Configuration package for the Concert robot with XBot2.

## Overview

This package provides configuration files for running the Concert robot with XBot2, both in simulation and on the real robot hardware.

## Structure

- `docker/` - Docker build and compose configurations
- `docker-base/` - Submodule with base docker utilities (xbot2_docker)
- `ecat/` - EtherCAT master configuration
- `gui/` - XBot2 GUI server and launcher configurations (ros1/ros2)
- `hal/` - Hardware abstraction layer configurations
- `joint_config/` - Joint control configurations (impedance, position, idle)
- `joint_map/` - EtherCAT ID to joint name mappings
- `xbot2/` - XBot2 core configurations (ros1/ros2)
- `config/` - Additional ROS configurations
- `launch/` - ROS launch files

## Usage

### Environment Setup

Source the setup script to configure environment variables:

```bash
source setup.sh
```

This sets up:
- `ECAT_MASTER_CONFIG` - Path to EtherCAT master config
- `CONCERT_LAUNCHER_DEFAULT_CONFIG` - Path to launcher config (ROS version dependent)
- `XBOT2_CONFIG` - Path to XBot2 config (ROS version dependent)

### Docker

Build docker images:

```bash
cd docker
./build-concert.bash ros2  # For ROS2
./build-concert.bash ros1  # For ROS1
```

### Real Robot

1. Start EtherCAT master:
   ```bash
   ecat_master
   ```

2. Start XBot2:
   ```bash
   xbot2-core --hw ec_idle  # or ec_pos, ec_imp
   ```

## Configuration

### Machine IPs

Update the machine IPs in `gui/ros1/concert_launcher_config.yaml` and `gui/ros2/concert_launcher_config.yaml`:

- `embedded@10.24.10.100` - Embedded PC (control)
- `concert@10.24.10.101` - Vision PC
- `concert@10.24.10.102` - Control PC

### Joint Configuration

Update joint names and mappings in:
- `joint_map/concert_joint_map.yaml` - EtherCAT ID to joint name mapping
- `joint_config/concert_ec_*.yaml` - Control gains per joint
