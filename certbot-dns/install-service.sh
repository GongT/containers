#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + STR_DOMAINS domains "list of domain name, eg: www.a.com,www.b.com"
arg_string - AUTH_DOMAIN auth_domain "domain auth alias"
arg_string + CF_ID id "cloudflare dns account id"
arg_string + CF_TOKEN token "cloudflare api token"
arg_string + ACCOUNT_EMAIL m/mail "acme account email"
arg_string - NOTIFY_MAIL_USER smtp-user "notify smtp username"
arg_string - NOTIFY_MAIL_PASS smtp-pass "notify smtp password"
arg_string - NOTIFY_MAIL_HUB smtp-server "notify smtp server url"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"CF_Token=$CF_TOKEN" \
		"CF_Account_ID=$CF_ID" \
		"ACCOUNT_EMAIL=$ACCOUNT_EMAIL" \
		"AUTH_DOMAIN=$AUTH_DOMAIN" \
		"NOTIFY_MAIL_USER=$NOTIFY_MAIL_USER" \
		"NOTIFY_MAIL_PASS=$NOTIFY_MAIL_PASS" \
		"NOTIFY_MAIL_HUB=$NOTIFY_MAIL_HUB"
)

mapfile -t -d ',' ARR_DOMAINS < <(echo "$STR_DOMAINS")
DOMAINS=()
for I in "${ARR_DOMAINS[@]}"; do
	DOMAINS+=($(echo $I))
done

create_pod_service_unit gongt/certbot-dns
unit_podman_image gongt/certbot-dns "${DOMAINS[@]}"
unit_podman_image_pull never
network_use_bridge

unit_start_notify output "everything works well, starting crond"
unit_body Restart no
unit_body RestartSec 10s
unit_body TimeoutStartSec 30s

unit_podman_hostname certbot
unit_podman_arguments "$ENV_PASS"
unit_body Environment FROM_SERVICE=yes
unit_fs_bind share/letsencrypt /etc/letsencrypt
unit_fs_bind data/acme.sh /opt/data
unit_fs_bind logs/acme.sh /log
shared_sockets_use
unit_finish
