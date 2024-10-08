#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

function common() {
	local PROFILE=$1
	local -i PORT=$2
	unit_podman_image registry.gongt.me/gongt/resiliosync
	# unit_data danger

	network_use_auto "$PORT"
	systemd_slice_type idle

	unit_start_notify output 'My PeerID:'
	# unit_body Restart always
	unit_body ExecStop '/usr/bin/podman exec $CONTAINER_ID bash /opt/stop.sh'

	unit_fs_bind "config/resiliosync/$PROFILE" /data/config
	unit_fs_bind "data/resiliosync/$PROFILE" /data/state
	unit_fs_bind "logs/resiliosync/$PROFILE" /var/log

	mkdir -p "$CONTAINERS_DATA_PATH/config/resiliosync/$PROFILE"
	cp "profiles/$PROFILE.sh" "$CONTAINERS_DATA_PATH/config/resiliosync/$PROFILE/profile.sh"

	shared_sockets_provide "resiliosync.$PROFILE"
	

	podman_engine_params --env="LANG=zh_CN.utf8" --env="PORT=$PORT" --env="PROFILE=$PROFILE"
}

create_pod_service_unit beatsaber-music-sync
unit_unit Description 'BeatSaber Music Packs Sync'
common "beatsaber" 35515
unit_fs_bind /data/Volumes/GameDisk/Download/BeatSaber /data/content
unit_finish
