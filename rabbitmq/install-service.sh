#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

if [[ -e /etc/MACHINE_ID ]]; then
	MACHINE_ID=$(</etc/MACHINE_ID)
	REQUIRED=-
else
	REQUIRED=+
fi

arg_string "$REQUIRED" MACHINE_ID h/machine "Machine Id use for rabbitmq nodename"
arg_flag NO_SSL no-ssl "Never using SSL"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"RABBITMQ_NODENAME=rabbit@$MACHINE_ID" \
		"HOSTNAME=$MACHINE_ID" \
		"NO_SSL=$NO_SSL"
)

create_pod_service_unit gongt/rabbitmq
unit_unit Description "rabbit mq"

# unit_podman_image_pull never

unit_podman_arguments "$ENV_PASS"

unit_start_notify output "Startup complete!"

unit_fs_bind data/rabbitmq /var/lib/rabbitmq/mnesia
unit_fs_bind share/nginx /etc/nginx
unit_fs_bind share/ssl /etc/ACME

unit_body LimitNOFILE 64000

if [[ "$NO_SSL" ]]; then
	network_use_auto 35672/tcp
else
	network_use_auto 35671/tcp
fi
systemd_slice_type infrastructure
shared_sockets_use

# healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

unit_finish
