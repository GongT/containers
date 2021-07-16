#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

DNS_SERVER=cf
SERVER=letsencrypt

arg_string + STR_DOMAINS domains "list of domain name, eg: www.a.com,www.b.com"
arg_string - DNS_SERVER dns "dns provider name (default=cf)"
arg_string + DNS_SERVER_PARAMS dns-options "dns provider config environment"
arg_string - SERVER acme "server selection (default=letsencrypt)"
arg_string + SERVER_PARAMS acme-options "acme server config environment"
arg_string - NOTIFY_TO alert "alert email sent target"
arg_string - NOTIFY_SMTP smtp "notify smtp setting (username:password@smpt.server.com)"
arg_finish "$@"

mapfile -d ';' -t DNS_SERVER_PARAMS_ARR < <(echo "$DNS_SERVER_PARAMS")
mapfile -d ';' -t SERVER_PARAMS_ARR < <(echo "$SERVER_PARAMS")

split_url_user_pass_host_port "$NOTIFY_SMTP"

ENV_PASS=$(
	safe_environment \
		"NOTIFY_MAIL_USER=$USERNAME" \
		"NOTIFY_MAIL_PASS=$PASSWORD" \
		"NOTIFY_MAIL_HUB=$DOMAIN" \
		"MAIL_TO=$NOTIFY_TO" \
		"SERVER=$SERVER" \
		"DNS_SERVER=$DNS_SERVER" \
		"${DNS_SERVER_PARAMS_ARR[@]}" \
		"${SERVER_PARAMS_ARR[@]}"
)

mapfile -t -d ',' ARR_DOMAINS < <(echo "$STR_DOMAINS")
DOMAINS=()
for I in "${ARR_DOMAINS[@]}"; do
	DOMAINS+=($(echo $I))
done

create_pod_service_unit gongt/acme
unit_podman_image gongt/acme "${DOMAINS[@]}"
# unit_podman_image_pull never
network_use_auto

unit_start_notify output "everything works well, starting crond"
# unit_body Restart no
unit_body RestartSec 10s
unit_body TimeoutStartSec 30min

unit_podman_hostname acme
unit_podman_arguments "$ENV_PASS"
unit_body Environment FROM_SERVICE=yes
unit_fs_bind share/ssl /etc/ACME
unit_fs_bind data/acme /opt/data
unit_fs_bind logs/acme /log
shared_sockets_use
unit_finish
