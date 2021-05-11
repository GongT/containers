#!/usr/bin/env bash

set -Eeuo pipefail

echo "acme container start: $*"

# shellcheck source=./lib.sh
source /opt/lib.sh

if [[ $# -eq 0 ]]; then
	die "empty input param"
fi

## prepare acme.sh config
info "create account config file..."
cat <<-EOF >"$ACME_SH_CONFIG_FILE"
	ACCOUNT_KEY_PATH="$ACME_SH_CONFIG_HOME/account.key"
	ACCOUNT_EMAIL="$ACCOUNT_EMAIL"
	LOG_FILE="/log/common.log"
	LOG_LEVEL=2
EOF

if [[ ${MAIL_TO+found} == found ]] && [[ $MAIL_TO ]]; then
	info "prepare email notify config..."
	cat <<-EOF >>"$ACME_SH_CONFIG_FILE"
		NOTIFY_HOOK="mail"
		MAIL_TO="$ACCOUNT_EMAIL"
		MAIL_FROM="$NOTIFY_MAIL_USER"
	EOF

	echo "root:$NOTIFY_MAIL_USER" >/etc/ssmtp/revaliases
	cat <<-EOF >/etc/ssmtp/ssmtp.conf
		UseTLS=Yes
		UseSTARTTLS=Yes
		mailhub=$NOTIFY_MAIL_HUB
		AuthUser=$NOTIFY_MAIL_USER
		AuthPass=$NOTIFY_MAIL_PASS
	EOF
fi

RELOAD_SRC=$(</opt/nginx-reload.sh)
cat <<-RELOAD_FAKE >/opt/nginx-reload.sh
	#!/bin/bash
	echo "reload temporary disabled..."
RELOAD_FAKE

create_nginx_lagacy_load "$1"
for DOMAIN; do
	reset_args
	push_args "$DOMAIN"
	create_nginx_config "$DOMAIN"

	if ! acme --install-cert --ecc "${BASE_ARGS[@]}"; then
		info "Issue cert of domain $DOMAIN..."
		acme --issue --dns dns_cf --keylength ec-256 "${BASE_ARGS[@]}" || die "Failed to create cert."
	fi
done

echo "$RELOAD_SRC" >/opt/nginx-reload.sh
acme --renew-all || die "Failed initial renew."

sleep 5
echo 'Ok, everything works well, starting crond...' >&2
/usr/sbin/crond -f -d 6
