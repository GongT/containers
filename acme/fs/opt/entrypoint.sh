#!/usr/bin/env bash

set -Eeuo pipefail

echo "acme 容器启动: $*"

# shellcheck source=./lib.sh
source /opt/lib.sh

function acme() {
	echo -e "\x1B[2m>> acme.sh $*\x1B[0m" >&2
	/bin/acme "$@"
}

chmod a+x /opt/curl

if [[ $# -eq 0 ]]; then
	die "缺少 ...domain 参数"
fi

## prepare acme.sh config
info "创建配置文件..."
mkdir -p "$LE_WORKING_DIR"
cat <<-EOF >"$ACCOUNT_CONF_PATH"
	DEFAULT_ACME_SERVER="$SERVER"
	ACCOUNT_KEY_PATH='/opt/data/account.key'
	ACCOUNT_EMAIL='${ACCOUNT_EMAIL:-"admin@example.com"}'
	USER_AGENT='containers/acme(https://github.com/gongt/containers)'
	USER_PATH='/usr/bin:/usr/local/bin'
	LOG_FILE='/log/common.log'
EOF

if [[ ${SMTP_TO+found} == found ]] && [[ $SMTP_TO ]]; then
	info "准备邮件通知配置..."

	cat <<-EOF >"$ACCOUNT_CONF_PATH"
		NOTIFY_LEVEL='2'
		NOTIFY_HOOK='smtp'
	EOF
fi

echo "options timeout:99" >>/etc/resolv.conf

if [[ ${1} == shell ]]; then
	echo "启动 shell..."
	exec /bin/bash --login -i
fi
if [[ ${1} == bash ]]; then
	echo "启动 bash..."
	exec "$@"
fi

case "$DNS_SERVER" in
cf)
	info "检查 DNS 是否可用: api.cloudflare.com"
	try_nslookup api.cloudflare.com
	;;
*)
	die "不兼容的DNS服务器 ${DNS_SERVER}"
	;;
esac

case "$SERVER" in
letsencrypt)
	info "向 letsencrypt 注册账户"
	try_nslookup prod.api.letsencrypt.org
	acme --update-account --server letsencrypt \
		|| acme --register-account --server letsencrypt
	;;
zerossl)
	info "向 zerossl 注册账户"
	acme --update-account --server zerossl \
		|| acme --register-account --server zerossl \
			--eab-kid "$EABID" \
			--eab-hmac-key "$EABKEY"
	;;
*)
	die "不兼容的证书服务器 ${SERVER}"
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
		info "为域名 $TARGET_DOMAIN (auth: $AUTH_DOMAIN) 签发证书..."
		acme --issue --dns "dns_$DNS_SERVER" "${BASE_ARGS[@]}" || die "无法为域名 $TARGET_DOMAIN 签发证书"
	fi
done

export TEMP_DISABLE_RELOAD=
acme --renew-all || die "初始续期失败"

echo 'Ok, everything works well.'
echo -e '\n\n'

trap 'echo "收到 SIGINT 信号, 退出！"; exit' INT
while sleep 1d; do
	info "唤醒acme"
	acme --renew-all || true
done
