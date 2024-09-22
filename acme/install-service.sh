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
arg_string - SMTP_TO alert "alert email sent target"
arg_string - NOTIFY_SMTP smtp "notify smtp setting (username:password@smpt.server.com:port)"
arg_finish "$@"

mapfile -d ';' -t DNS_SERVER_PARAMS_ARR < <(echo "$DNS_SERVER_PARAMS")
mapfile -d ';' -t SERVER_PARAMS_ARR < <(echo "$SERVER_PARAMS")

split_url_user_pass_host_port "$NOTIFY_SMTP"
SMTP_USERNAME="$USERNAME"
SMTP_PASSWORD="$PASSWORD"
SMTP_HOST_NAME="$HOST_NAME"
SMTP_PORT_NUMBER="$PORT_NUMBER"

mapfile -t -d ',' ARR_DOMAINS < <(echo "$STR_DOMAINS")
DOMAINS=()
for I in "${ARR_DOMAINS[@]}"; do
	DOMAINS+=("$(trim "$I")")
done

create_pod_service_unit gongt/acme

environment_variable \
	"SMTP_USERNAME=$SMTP_USERNAME" \
	"SMTP_PASSWORD=$SMTP_PASSWORD" \
	"SMTP_HOST=$SMTP_HOST_NAME" \
	"SMTP_PORT=$SMTP_PORT_NUMBER" \
	"SMTP_TO=$SMTP_TO" \
	"SERVER=$SERVER" \
	"DNS_SERVER=$DNS_SERVER" \
	"PROXY=$PROXY" \
	"${DNS_SERVER_PARAMS_ARR[@]}" \
	"${SERVER_PARAMS_ARR[@]}"

unit_podman_image registry.gongt.me/gongt/acme
unit_podman_cmdline "${DOMAINS[@]}"

# unit_podman_image_pull never
# unit_body Restart no

network_use_auto
systemd_slice_type normal

unit_start_notify output "everything works well"
unit_body RestartSec 10s
unit_body TimeoutStartSec 30min

unit_podman_hostname acme
unit_body Environment FROM_SERVICE=yes
unit_fs_bind share/ssl /etc/ACME
unit_fs_bind data/acme /opt/data
unit_fs_bind logs/acme /log

shared_sockets_use

unit_finish
