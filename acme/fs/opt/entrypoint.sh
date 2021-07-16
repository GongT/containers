#!/usr/bin/env bash

set -Eeuo pipefail

echo "acme container start: $*"

# shellcheck source=./lib.sh
source /opt/lib.sh

if [[ $# -eq 0 ]]; then
	die "missing domain arguments"
fi
if [[ ${1} == bash ]]; then
	exec "$@"
fi

if [[ $# -eq 0 ]]; then
	die "empty input param"
fi

## prepare acme.sh config
info "create account config file..."
cat <<-EOF >"$ACME_SH_CONFIG_FILE"
	ACCOUNT_KEY_PATH="$ACME_SH_CONFIG_HOME/account.key"
	LOG_LEVEL=2
EOF

replace_config LOG_FILE "/log/common.log"

if [[ ${MAIL_TO+found} == found ]] && [[ $MAIL_TO ]]; then
	info "prepare email notify config..."
	cat <<-EOF >>"$ACME_SH_CONFIG_FILE"
		NOTIFY_HOOK="mail"
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

echo "options timeout:999" >>/etc/resolv.conf

case "$DNS_SERVER" in
cf)
	nslookup api.cloudflare.com
	;;
esac

case "$SERVER" in
letsencrypt)
	replace_config MAIL_TO "$ACCOUNT_EMAIL"
	replace_config ACCOUNT_EMAIL "$ACCOUNT_EMAIL"
	acme --register-account
	;;
zerossl)
	info "register account to zerossl"
	acme --register-account --server zerossl \
		--eab-kid "$EABID" \
		--eab-hmac-key "$EABKEY"
	;;
esac

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
		acme --issue --dns "dns_$DNS_SERVER" --keylength ec-256 "${BASE_ARGS[@]}" || die "Failed to create cert."
	fi
done

echo "$RELOAD_SRC" >/opt/nginx-reload.sh
acme --renew-all || die "Failed initial renew."

sleep 5
echo 'Ok, everything works well, starting crond...' >&2
/usr/sbin/crond -f -d 6
