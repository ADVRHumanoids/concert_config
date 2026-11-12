SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# kernel version
export KERNEL_VER=$(uname -r | cut -d '.' -f 1)

# ros config
export ROS_IP=10.24.10.100

# ssh aliases
alias ssh_control='ssh concert@10.24.10.102'
alias ssh_vision='ssh concert@10.24.10.101'

# enable ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/concert-noble-ros2-xeno/setup.sh

# config path
export CONFIG_PATH_DOCKER=docker/embedded_profile_docker.bash

# set concert launcher output folder
export CONCERT_LAUNCHER_STDOUT_PATH=/var/log/concert_launcher