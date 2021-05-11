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

	if [[ ${AUTH_DOMAIN+found} == found ]] && [[ $AUTH_DOMAIN ]]; then
		BASE_ARGS+=(--domain-alias "$AUTH_DOMAIN")
	fi
}

reset_args

function push_args() {
	local TARGET_DOMAIN=$1
	local -r CERT_INSTALL_DIR="/etc/letsencrypt/live/$TARGET_DOMAIN"
	mkdir -p "$CERT_INSTALL_DIR"

	BASE_ARGS+=(
		-d "$TARGET_DOMAIN"
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

	local CFG="/etc/letsencrypt/nginx/${DOMAIN_TXT}.conf"

	info "create nginx config: $CFG"
	cat <<-NGX_CFG >"$CFG"
		ssl_certificate "/etc/letsencrypt/live/$DOMAIN/fullchain.pem";
		ssl_certificate_key "/etc/letsencrypt/live/$DOMAIN/privkey.pem";
		ssl_trusted_certificate "/etc/letsencrypt/live/$DOMAIN/cert.pem";
	NGX_CFG
}

function create_nginx_lagacy_load() {
	local DOMAIN=$1
	if [[ $DOMAIN == '*.'* ]]; then
		DOMAIN=${DOMAIN:2}
	fi
	local CFG="/etc/letsencrypt/nginx/load.conf"
	info "create nginx config: $CFG"
	echo "include \"/etc/letsencrypt/nginx/${DOMAIN}.conf\";" >"$CFG"
}
