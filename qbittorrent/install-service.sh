#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/qbittorrent
unit_podman_image registry.gongt.me/gongt/qbittorrent
unit_unit Description qbittorrent

# unit_body Restart always
unit_data danger
systemd_slice_type idle

add_network_privilege
network_use_veth bridge0
podman_engine_params --mac-address=4A:E1:A2:4E:D5:6E

unit_fs_bind config/qbittorrent/main /opt/qBittorrent/config
unit_fs_bind data/qbittorrent/main /opt/qBittorrent/data
unit_fs_bind data/qbittorrent/main/HOME /home/media_rw
unit_fs_bind /data/Volumes /data/Volumes

unit_body TimeoutStartSec 2min
shared_sockets_provide qbittorrent-admin

for I in /data/Volumes/*; do
	unit_unit RequiresMountsFor "${I}"
done

unit_finish


function create() {
	local NAME=$1 MAC_ADDR=$2 DATA_DIR=$3
	ensure_user_exists "qbt-${NAME}" 

	create_pod_service_unit "qbittorrent-${NAME}"
	unit_podman_image registry.gongt.me/gongt/qbittorrent
	unit_unit Description "qbittorrent @ ${DATA_DIR}"

	# unit_body Restart always
	unit_data danger
	systemd_slice_type idle

	add_network_privilege
	network_use_veth bridge0
	podman_engine_params "--mac-address=${MAC_ADDR}"
	environment_variable "SUBSERVICE=${NAME}" "USER_NAME=qbt-${NAME}" "USER_ID=$(get_uid_of_user "qbt-${NAME}")" "GROUP_ID=$(get_gid_of_group "users")"

	unit_fs_bind "config/qbittorrent/${NAME}" /opt/qBittorrent/config
	unit_fs_bind "data/qbittorrent/${NAME}" /opt/qBittorrent/data
	unit_fs_bind "data/qbittorrent/${NAME}/HOME" /home/media_rw
	unit_fs_bind "${DATA_DIR}" /data

	unit_body TimeoutStartSec 2min
	shared_sockets_provide "qbittorrent-${NAME}"

	unit_unit RequiresMountsFor "${DATA_DIR}"

	unit_finish
}

create animation "3a:e7:97:ca:b6:16" /data/Volumes/Anime
