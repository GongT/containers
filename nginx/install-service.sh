#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

USERNAME=
PASSWORD=
NETTYPE=
function die() {
	echo "$@" >&2 ; exit 1
}
function info() {
	echo -e "\e[38;5;14m$*\e[0m"
}
function check_args() {
	while [[ $# -gt 0 ]]; do
		local K=$1
		shift
		case "$K" in
		-p)
			eval PASSWORD=${1}
		;;
		-u)
			eval USERNAME=${1}
		;;
		-n)
			eval NETTYPE=${1}
		;;
		--)
			return
		;;
		*)
			die "Unknown argument: $K"
		esac
		shift
	done
}
check_args $(getopt -o u:p:n: -- "$@")


if [[ -z "$USERNAME" ]]; then
	die "-u is required (basic auth username)"
fi
if [[ -z "$PASSWORD" ]]; then
	die "-p is required (basic auth password)"
fi
if [[ -z "$NETTYPE" ]]; then
	die "-n is required (network type)"
fi

echo "USERNAME=$USERNAME"
echo "PASSWORD=$PASSWORD"
echo "NETTYPE=$NETTYPE"

if [[ "$NETTYPE" == "host" ]] ; then
	info "Using host network"
	NET_TYPE="--publish 80:80 --publish 443:443"
elif [[ "$NETTYPE" == "bridge" ]] ; then
	GMAC=$(echo "$(hostname).nginx" | sha1sum | head -c12 |  sed 's/../&:/g;s/:$//')
	info "Using bridge0 network (Mac Address $GMAC)"
	NET_TYPE="--net=bridge0 --mac-address=$GMAC --dns=none --http-proxy=false "
else
	die "Usage: $0 <bridge|host>"
fi
ENV_FIELDS=""

cat << EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
StartLimitInterval=11
StartLimitBurst=2
Wants=php-fpm.service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/nginx.pid
ExecStartPre=-/usr/bin/podman rm --ignore --force nginx
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/nginx.pid \\
	--hostname=webservice --name=nginx \\
	--systemd=false \\
	--mount=type=bind,src=/data/AppData/config/nginx,dst=/config \\
	--mount=type=bind,src=/data/AppData/logs/nginx,dst=/var/log \\
	--mount=type=tmpfs,tmpfs-size=1M,destination=/run \\
	--mount=type=tmpfs,tmpfs-size=512M,destination=/tmp \\
	--volume=letsencrypt:/etc/letsencrypt \\
	--volume=wellknown:/etc/wellknown \\
	--env="USERNAME=${USERNAME}" --env="PASSWORD=${PASSWORD}" \\
	$NET_TYPE \\
	--pull=never --rm -t gongt/nginx
RestartPreventExitStatus=125 126 127
ExecReload=/usr/bin/podman exec nginx nginx -s reload
ExecStop=/usr/bin/podman stop -t 10 nginx
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

# --log-driver=journald --log-opt tag="{{.ImageName}}" \


EOF

info "nginx.service created"

systemctl daemon-reload
exit 0

echo '[Unit]
# TODO

' > /usr/lib/systemd/system/certbot-renew.timer

echo '[Unit]
Description=(this is called by timer) call certbot renew
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/certbot renew
PrivateTmp=yes
Restart=no
RemainAfterExit=no

' > /usr/lib/systemd/system/certbot-renew.service


systemctl daemon-reload
systemctl enable certbot-renew.timer nginx.service

if ! grep -q nginx /etc/passwd ; then
	useradd \
		--home-dir /var/lib/nginx --no-create-home \
		--uid 996 --gid 992 \
		--shell /sbin/nologin \
		--comment 'Nginx web server' \
		nginx 
fi

if [[ -L /etc/nginx ]]; then
	unlink /etc/nginx
elif [[ -d /etc/nginx ]]; then
	rm -rf /etc/nginx
elif [[ -e /etc/nginx ]]; then
	rm -f /etc/nginx
fi

ln -s "`pwd`/config" /etc/nginx
