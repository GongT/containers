#!/usr/bin/env bash

BASE_ARGS=()
FC=''
STIME=$(date '+%F.%T')
export LE_WORKING_DIR=/opt/home
export ACCOUNT_CONF_PATH="$LE_WORKING_DIR/account.conf"
export NO_TIMESTAMP=1

function info() {
	echo "$@" >&2
}

function die() {
	info "$@"
	exit 233
}

function logfile_name() {
	local -r KIND=$1
	echo "/log/$STIME.$KIND.log"
}

function reset_args() {
	BASE_ARGS=(
		--server "$SERVER"
		--log "$(logfile_name acme)"
		--log-level 2
		--reloadcmd "bash /opt/nginx-reload.sh"
		--renew-hook "bash /opt/nginx-reload.sh"
	)
}

reset_args

function push_args() {
	local TARGET_DOMAIN=$1 AUTH_DOMAIN=$2

	local -r CERT_INSTALL_DIR="/etc/ACME/$TARGET_DOMAIN"
	mkdir -p "$CERT_INSTALL_DIR"

	BASE_ARGS+=(
		-d "$TARGET_DOMAIN"
	)

	if [[ $AUTH_DOMAIN ]]; then
		BASE_ARGS+=(--domain-alias "$AUTH_DOMAIN")
	fi

	BASE_ARGS+=(
		--cert-file "${CERT_INSTALL_DIR}/cert.pem"
		--key-file "${CERT_INSTALL_DIR}/privkey.pem"
		--ca-file "${CERT_INSTALL_DIR}/ca.pem"
		--fullchain-file "${CERT_INSTALL_DIR}/fullchain.pem"
	)
}

function create_nginx_config() {
	local DOMAIN=$1 DOMAIN_TXT=$1

	if [[ $DOMAIN_TXT == '*.'* ]]; then
		DOMAIN_TXT=${DOMAIN_TXT:2}
	fi

	mkdir -p "/etc/ACME/nginx"
	local CFG="/etc/ACME/nginx/${DOMAIN_TXT}.conf"

	info "create nginx config: $CFG"
	cat <<-NGX_CFG >"$CFG"
		ssl_certificate "/etc/ACME/$DOMAIN/fullchain.pem";
		ssl_certificate_key "/etc/ACME/$DOMAIN/privkey.pem";
		ssl_trusted_certificate "/etc/ACME/$DOMAIN/cert.pem";
	NGX_CFG
}

function create_nginx_lagacy_load() {
	local DOMAIN=$1
	if [[ $DOMAIN == '*.'* ]]; then
		DOMAIN=${DOMAIN:2}
	fi

	mkdir -p "/etc/ACME/nginx"
	local CFG="/etc/ACME/nginx/load.conf"
	info "create nginx config: $CFG"
	echo "include \"/etc/ACME/nginx/${DOMAIN}.conf\";" >"$CFG"
}

function try_nslookup() {
	local HOST=$1
	echo "try resolve $HOST" >&2
	while ! nslookup "$HOST" >/dev/null; do
		echo "failed." >&2
		sleep 5
	done
	echo "success." >&2
}

function acme() {
	echo -e "\x1B[2m>> acme.sh $*\x1B[0m" >&2
	PATH="/opt:$PATH" bash /opt/acme.sh/acme.sh "$@"
}
