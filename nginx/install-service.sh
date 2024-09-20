#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + USERNAME u/user "basic auth username (*)"
arg_string + PASSWORD p/pass "basic auth password (*)"
arg_flag DISABLE_SSL no-ssl "disable listen 443 and SSL related config"
arg_string PUBLISH publish "additional publishing ports"
arg_flag CENSORSHIP censorship "is http/s port unavailable"
arg_finish "$@"

PUBPORTS=(80/tcp 8883/tcp)
if ! [[ $DISABLE_SSL ]]; then
	PUBPORTS+=(443)
fi
if [[ $CENSORSHIP == yes ]]; then
	PUBPORTS+=(59080/tcp)
	if ! [[ $DISABLE_SSL ]]; then
		PUBPORTS+=(59443)
	fi
fi
if [[ -n ${PUBLISH-} ]]; then
	PUBPORTS+=(${PUBLISH})
fi

create_pod_service_unit nginx
unit_podman_image registry.gongt.me/gongt/nginx
unit_unit Description nginx - high performance web server
unit_unit After gateway-network.pod.service

network_use_pod gateway
systemd_slice_type normal

environment_variable \
	"USERNAME=$USERNAME" \
	"PASSWORD=$PASSWORD" \
	"CENSORSHIP=$CENSORSHIP" \
	"DISABLE_SSL=$DISABLE_SSL"

unit_start_notify socket

unit_fs_bind /data/DevelopmentRoot /data/DevelopmentRoot
unit_fs_bind data/nginx /data
unit_fs_bind config/nginx /config
unit_fs_bind logs/nginx /var/log/nginx
unit_fs_tempfs 8M /run
unit_fs_tempfs 2G /tmp
if ! [[ $DISABLE_SSL ]]; then
	unit_fs_bind share/ssl /etc/ACME
fi
shared_sockets_provide http https nginx.reload
unit_body RestartSec 30s

unit_finish

LOGROTATE='
/data/AppData/logs/nginx/*.log {
	weekly
	missingok
	notifempty
	sharedscripts
	rotate 2
	compress
	delaycompress
}
'

if is_root; then
	write_file /etc/logrotate.d/nginx "${LOGROTATE}"
fi
