#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

function common() {
	local PROFILE=$1 TITLE="$2"
	local -i PORT=$3
	unit_podman_image registry.gongt.me/gongt/resiliosync

	network_use_pod gateway "${PORT}/tcp"
	systemd_slice_type idle

	unit_body Restart no
	unit_data danger
	unit_body TimeoutStartSec 1min

	unit_fs_bind "data/resiliosync/$PROFILE" /data/state
	unit_fs_bind "logs/resiliosync/$PROFILE" /var/log

	if [[ -e "profiles/$PROFILE.sh" ]]; then
		mkdir -p "$CONTAINERS_DATA_PATH/config/resiliosync/$PROFILE"
		cp "profiles/$PROFILE.sh" "$CONTAINERS_DATA_PATH/config/resiliosync/$PROFILE/profile.sh"
		unit_fs_bind "config/resiliosync/$PROFILE" /data/config
	fi

	shared_sockets_provide "resiliosync.$PROFILE"

	podman_engine_params \
		--ulimit=nofile=1048576:1048576 \
		--env="PORT=$PORT" \
		--env="PROFILE=$PROFILE" \
		--env="SERVER_NAME=$TITLE"
}

create_pod_service_unit beatsaber-music-sync
unit_unit Description 'BeatSaber Music Packs Sync'
common "beatsaber" "初绎的光剑游戏谱面镜像" 35515
unit_fs_bind /data/Volumes/GameDisk/BeatSaber/MusicSync /data/content
unit_finish

create_pod_service_unit resiliosync
unit_unit Description 'My personal resiliosync server'
common "resiliosync" "初绎的数据同步服务器" 35516
unit_fs_bind /data/Volumes/UserData/ResilioSync /data/content
unit_finish
