_CONCERT_CLIENT_PROFILE_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ssh aliases
alias ssh_embedded='ssh embedded@10.24.15.100'
alias ssh_control='ssh concert@10.24.15.102'
alias ssh_vision='ssh concert@10.24.15.101'

# enable ros2 alias to login into docker container
source $_CONCERT_CLIENT_PROFILE_SCRIPT_DIR/../docker/concert-noble-ros2/setup.sh

# specific ros domain id for clients to avoid any overlap with the local ros2 network
export ROS_DOMAIN_ID=42

# configure ros automatic discovery range to localhost only, to avoid any overlap with the robot's lan
export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST

# config path
export CONFIG_PATH_DOCKER=docker/client_profile_docker.bash

# connect to the robot's vpn via wireguard
function concert_connect_wg() {
    $_CONCERT_CLIENT_PROFILE_SCRIPT_DIR/../network/wg/connect-wg.bash "$@"
}

# enable zenoh bridge
function concert_connect_zenoh() {
    cd $_CONCERT_CLIENT_PROFILE_SCRIPT_DIR/../docker/concert-noble-ros2
    docker compose up -d zenoh_bridge_client
    cd -
}

# do it all
function concert_connect() {
    concert_connect_wg "$@"
    concert_connect_zenoh
}
