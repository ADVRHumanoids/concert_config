SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros config
export ROS_IP=10.24.10.101

# enable ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/concert-noble-ros2-jetpack-r36.5/setup.sh

# configure zenoh bridge to listen on all interfaces (default)
export ZENOH_BRIDGE_ARGS=""

# ssh aliases
alias ssh_embedded='ssh embedded@10.24.10.100'
alias ssh_control='ssh concert@10.24.10.102'

# config path
export CONFIG_PATH_DOCKER=docker/perception_profile_docker.bash

# set concert launcher output folder
export CONCERT_LAUNCHER_STDOUT_PATH=/var/log/concert_launcher
