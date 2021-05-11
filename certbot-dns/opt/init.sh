#!/bin/bash

set -uo pipefail

function die() {
	echo "$@" >&2
	exit 66
}

function acme() {
	echo " + /usr/bin/acme.sh $*"
	bash /usr/bin/acme.sh "$@"
}

ACME_SH_CONFIG_HOME=/etc/letsencrypt/acme.sh

ACME_CERT_FOLDER="/etc/letsencrypt/live/*.$TARGET_DOMAIN"
FC="${ACME_CERT_FOLDER}/fullchain.pem"
mkdir -p "$ACME_CERT_FOLDER"
BASE_ARGS=(
	-d "*.$TARGET_DOMAIN"
	--cert-file "${ACME_CERT_FOLDER}/cert.pem"
	--key-file "${ACME_CERT_FOLDER}/privkey.pem"
	--fullchain-file "$FC"
	--reloadcmd "bash /opt/nginx-reload.sh"
	--config-home "$ACME_SH_CONFIG_HOME"
)

function do_install() {
	echo "Install cert files into letsencrypt folder"
	acme --install-cert "*.$TARGET_DOMAIN" "${BASE_ARGS[@]}"
}

## install
echo "
ACCOUNT_KEY_PATH='$ACME_SH_CONFIG_HOME/account.key'
ACCOUNT_EMAIL='$EMAIL'
" >"$ACME_SH_CONFIG_HOME/account.conf"

mkdir -p /etc/letsencrypt/nginx
echo "
ssl_certificate $ACME_CERT_FOLDER/fullchain.pem;
ssl_certificate_key $ACME_CERT_FOLDER/privkey.pem;
ssl_trusted_certificate $ACME_CERT_FOLDER/cert.pem;
" >"/etc/letsencrypt/nginx/load.conf"
##

cat_resolv() {
	echo "== resolv.conf ======================="
	cat /etc/resolv.conf
	echo "======================================"
}

LOGFILE="/log/$TARGET_DOMAIN/$(date '+%F.%T').init.log"

if acme --install-cert --ecc "${BASE_ARGS[@]}"; then
	echo "installed cert files at $FC, try renew..." >&2
	cat_resolv
	acme --renew-all --ecc "${BASE_ARGS[@]}" 2>&1 | tee "$LOGFILE"
else
	echo "cannot install cer files, try issue new..." >&2
	cat_resolv
	acme --issue --dns dns_cf --keylength ec-256 \
		--domain-alias "$AUTH_DOMAIN" \
		"${BASE_ARGS[@]}" 2>&1 | tee "$LOGFILE" \
		|| die "Failed to CREATE cert."
fi

if ! [[ -e $FC ]]; then
	die "Fatal: No cert file in place."
fi

BASE_ARGS_ESCAPE=()
for i in "${BASE_ARGS[@]}"; do
	BASE_ARGS_ESCAPE+=("'$i'")
done

mkdir -p "/log/$TARGET_DOMAIN"

echo 'Install cronjob...' >&2
echo '======================================' >&2
cat <<-CRON_WORK_FILE >/etc/periodic/weekly/acme-renew
	#!/bin/bash

	LOGFILE="/log/$TARGET_DOMAIN/\$(date '+%F.%T').log"
	{
		echo acme.sh --renew-all --ecc ${BASE_ARGS_ESCAPE[*]}
		acme.sh --renew-all --ecc ${BASE_ARGS_ESCAPE[*]} 2>&1
		echo "Execute finish, code: \$?"
	} | tee "\$LOGFILE"

CRON_WORK_FILE

chmod a+x /etc/periodic/weekly/acme-renew
echo '======================================' >&2

sleep 5

echo 'Ok, everything works well, starting crond...' >&2
exec /usr/sbin/crond -f -d 6
