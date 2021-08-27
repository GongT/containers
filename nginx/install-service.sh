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

ENV_PASS=$(
	safe_environment \
		"USERNAME=$USERNAME" \
		"PASSWORD=$PASSWORD" \
		"CENSORSHIP=$CENSORSHIP" \
		"DISABLE_SSL=$DISABLE_SSL"
)

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
if [[ -n ${PUBLISH:-} ]]; then
	PUBPORTS+=(${PUBLISH})
fi

create_pod_service_unit gongt/nginx
unit_unit Description nginx - high performance web server
network_use_auto "${PUBPORTS[@]}"
unit_podman_arguments "$ENV_PASS"
unit_start_notify output "start worker process"
# unit_body Restart always
unit_fs_bind data/nginx /data
unit_fs_bind config/nginx /config
unit_fs_bind logs/nginx /var/log/nginx
unit_fs_tempfs 1M /run
unit_fs_tempfs 512M /tmp
unit_fs_bind share/nginx /config.auto
if ! [[ $DISABLE_SSL ]]; then
	unit_fs_bind share/ssl /etc/ACME
fi
shared_sockets_use
unit_reload_command '/usr/bin/podman exec nginx bash /usr/bin/safe-reload'

healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

unit_finish

write_file /etc/logrotate.d/nginx <<-LOGR
	/data/AppData/logs/nginx/*.log {
	    weekly
	    missingok
	    notifempty
	    sharedscripts
	    rotate 2
	    compress
	    delaycompress
	}
LOGR
