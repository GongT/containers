#!/usr/bin/env bash

BASE_ARGS=()
FC=''
STIME=$(date '+%F.%T')
declare -r ACME_SH_CONFIG_HOME=/opt/data
declare -r ACME_SH_CONFIG_FILE="$ACME_SH_CONFIG_HOME/account.conf"

function info() {
	echo "$@" >&2
}

function die() {
	info "$@"
	exit 66
}

function logfile_name() {
	local -r KIND=$1
	echo "/log/$STIME.$KIND.log"
}
function acme() {
	info " + /opt/acme.sh/acme.sh $*"
	bash /opt/acme.sh/acme.sh "${BASE_ARGS[@]}" "$@"
}

function reset_args() {
	BASE_ARGS=(
		--server "$SERVER"
		--no-color
		--config-home "$ACME_SH_CONFIG_HOME"
		--accountkey "$ACME_SH_CONFIG_HOME/account.key"
		--accountconf "$ACME_SH_CONFIG_FILE"
		--log "$(logfile_name acme)"
		--log-level 2
		--output-insecure
		--reloadcmd "bash /opt/nginx-reload.sh"
		--renew-hook "bash /opt/nginx-reload.sh"
	)
}

reset_args

function push_args() {
	local TARGET_DOMAIN=$1 AUTH_DOMAIN=

	if [[ $TARGET_DOMAIN == *:* ]]; then
		AUTH_DOMAIN=${TARGET_DOMAIN#*:}
		TARGET_DOMAIN=${TARGET_DOMAIN%:*}
	fi

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
		--fullchain-file "${CERT_INSTALL_DIR}/fullchain.pem"
	)
}

function load_config() {
	set -a
	# shellcheck source=/dev/null
	source "$ACME_SH_CONFIG_FILE"
	set +a
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
		ssl_certificate "/etc/ACME/live/$DOMAIN/fullchain.pem";
		ssl_certificate_key "/etc/ACME/live/$DOMAIN/privkey.pem";
		ssl_trusted_certificate "/etc/ACME/live/$DOMAIN/cert.pem";
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
