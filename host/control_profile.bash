SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros config
export ROS_IP=10.24.15.102

# enable ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/concert-noble-ros2/setup.sh

# configure zenoh bridge to listen on all interfaces (default)
export ZENOH_BRIDGE_ARGS=""

# ssh aliases
alias ssh_embedded='ssh embedded@10.24.15.100'
alias ssh_vision='ssh concert@10.24.15.101'

# config path
export CONFIG_PATH_DOCKER=docker/control_profile_docker.bash

# render group id for va hw accel
export RENDER_GID="$(stat -c '%g' /dev/dri/renderD128)"

# set concert launcher output folder
export CONCERT_LAUNCHER_STDOUT_PATH=/var/log/concert_launcher
