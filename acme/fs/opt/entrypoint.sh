#!/usr/bin/env bash

set -Eeuo pipefail

echo "acme container start: $*"

# shellcheck source=./lib.sh
source /opt/lib.sh

chmod a+x /opt/curl

if [[ $# -eq 0 ]]; then
	die "missing domain arguments"
fi

export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" ALL_PROXY="$PROXY"
export http_proxy="$PROXY" https_proxy="$PROXY" all_proxy="$PROXY"

## prepare acme.sh config
info "create account config file..."
mkdir -p "$LE_WORKING_DIR"
cat <<-EOF >"$ACCOUNT_CONF_PATH"
	DEFAULT_ACME_SERVER="$SERVER"
	ACCOUNT_KEY_PATH='/opt/data/account.key'
	ACCOUNT_EMAIL='${ACCOUNT_EMAIL:-"admin@example.com"}'
	USER_AGENT='containers/acme(https://github.com/gongt/containers)'
	USER_PATH='/usr/bin:/usr/local/bin'
	LOG_FILE='/log/common.log'
EOF

export CA_HOME="/opt/data/ca"
export CERT_HOME="/opt/data/certs"

if [[ ${SMTP_TO+found} == found ]] && [[ $SMTP_TO ]]; then
	info "prepare email notify config..."

	export SMTP_FROM="$SMTP_USERNAME"
	export SMTP_SECURE='tls'
	export SMTP_TIMEOUT='30'
	export SMTP_BIN='/usr/bin/python3'

	cat <<-EOF >"$ACCOUNT_CONF_PATH"
		NOTIFY_LEVEL='2'
		NOTIFY_HOOK='smtp'
	EOF
fi

echo "options timeout:99" >>/etc/resolv.conf

if [[ ${1} == bash ]]; then
	exec "$@"
fi

case "$DNS_SERVER" in
cf)
	info "check dns work for api.cloudflare.com"
	try_nslookup api.cloudflare.com
	;;
esac

case "$SERVER" in
letsencrypt)
	info "register account to letsencrypt"
	try_nslookup prod.api.letsencrypt.org
	acme --update-account --server letsencrypt || acme --register-account --server letsencrypt
	;;
zerossl)
	info "register account to zerossl"
	acme --update-account --server zerossl || acme --register-account --server zerossl \
		--eab-kid "$EABID" \
		--eab-hmac-key "$EABKEY"
	;;
esac

export TEMP_DISABLE_RELOAD=1

create_nginx_lagacy_load "$1"
for DOMAIN; do
	reset_args

	if [[ $DOMAIN == *:* ]]; then
		AUTH_DOMAIN=${DOMAIN#*:}
		TARGET_DOMAIN=${DOMAIN%:*}
	else
		AUTH_DOMAIN=
		TARGET_DOMAIN=${DOMAIN}
	fi

	push_args "$TARGET_DOMAIN" "$AUTH_DOMAIN"
	create_nginx_config "$TARGET_DOMAIN"

	if ! acme --install-cert --ecc "${BASE_ARGS[@]}"; then
		info "Issue cert of domain $TARGET_DOMAIN (auth: $AUTH_DOMAIN)..."
		acme --issue --dns "dns_$DNS_SERVER" "${BASE_ARGS[@]}" || die "Failed to create cert."
	fi
done

export TEMP_DISABLE_RELOAD=
acme --renew-all || die "Failed initial renew."

sleep 5
echo 'Ok, everything works well.'
echo -e '\n\n'

trap 'echo "got sigint, exiting."; exit' INT
while sleep 1d; do
	info "wakeup call acme"
	acme --renew-all || true
done
