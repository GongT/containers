#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + TARGET_DOMAIN target_domain "domain name"
arg_string + AUTH_DOMAIN auth_domain "domain auth alias"
arg_string + CF_ID id "cloudflare dns account id"
arg_string + CF_TOKEN token "cloudflare api token"
arg_string + EMAIL m/mail "acme account email"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"CF_Token=$CF_TOKEN" \
		"CF_Account_ID=$CF_ID" \
		"TARGET_DOMAIN=$TARGET_DOMAIN" \
		"AUTH_DOMAIN=$AUTH_DOMAIN" \
		"EMAIL=$EMAIL"
)


create_pod_service_unit gongt/certbot-dns
unit_podman_image gongt/certbot

unit_start_notify output "everything works well, starting crond"
unit_body Restart on-failure
unit_body RestartSec 10s
unit_body TimeoutStartSec 30s

unit_podman_hostname certbot
unit_podman_arguments "$ENV_PASS"
unit_body Environment FROM_SERVICE=yes
unit_fs_bind share/letsencrypt /etc/letsencrypt
unit_fs_bind share/sockets /run/sockets
unit_finish
