#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + USERNAME u/user "basic auth username (*)"
arg_string + PASSWORD p/pass "basic auth password (*)"
arg_flag     CENSORSHIP censorship "is http/s port unavailable"
arg_finish "$@"


ENV_PASS=$(
	safe_environment \
		"USERNAME=$USERNAME" \
		"PASSWORD=$PASSWORD" \
		"CENSORSHIP=$CENSORSHIP"
)

cat << EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
StartLimitInterval=11
StartLimitBurst=2
Wants=php-fpm.service
After=network-online.target $INFRA_DEP
Requires=$INFRA_DEP
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/nginx.pid
ExecStartPre=-/usr/bin/podman rm --ignore --force nginx
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/nginx.pid \\
	--hostname=webservice --name=nginx \\
	$NETWORK_TYPE $ENV_PASS \\
	--systemd=false --log-opt=path=/dev/null \\
	--mount=type=bind,src=/data/AppData/config/nginx,dst=/config \\
	--mount=type=bind,src=/data/AppData/logs/nginx,dst=/var/log/nginx \\
	--mount=type=tmpfs,tmpfs-size=1M,destination=/run \\
	--mount=type=tmpfs,tmpfs-size=512M,destination=/tmp \\
	--volume=letsencrypt:/etc/letsencrypt \\
	--volume=sockets:/run/sockets \\
	--pull=never --rm gongt/nginx
RestartPreventExitStatus=125 126 127
ExecReload=/usr/bin/podman exec nginx nginx -s reload
ExecStop=/usr/bin/podman stop -t 10 nginx
Restart=always
RestartSec=5

[Install]
WantedBy=machines.target

EOF

info "nginx.service created"

systemctl daemon-reload
systemctl enable nginx.service
