#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + TARGET_DOMAIN target_domain "domain name"
arg_string + AUTH_DOMAIN auth_domain "domain auth alias"
arg_string + CF_ID id "cloudflare dns account id"
arg_string + CF_TOKEN token "cloudflare api token"
arg_string + EMAIL m/mail "acme account email"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"CF_Token=$CF_TOKEN" \
		"CF_Account_ID=$CF_ID" \
		"TARGET_DOMAIN=$TARGET_DOMAIN" \
		"AUTH_DOMAIN=$AUTH_DOMAIN" \
		"EMAIL=$EMAIL"
)

mkdir -p /data/AppData/logs/certbot /data/AppData/config/nginx

echo "#!/usr/bin/env bash

exec podman exec -it certbot \\
	--env \\
	bash /usr/local/bin/create-sub-domain.sh "\$1"
" > /usr/local/bin/certbot-create-domain
chmod a+x /usr/local/bin/certbot-create-domain

echo "[Unit]
Description=call certbot renew every week
StartLimitInterval=60
StartLimitBurst=2
After=network-online.target virtual-gateway.service
Wants=network-online.target
Requires=virtual-gateway.service
Conflicts=certbot-nginx.service

[Service]
Type=simple
PIDFile=/run/certbot-dns.pid
Environment=FROM_SERVICE=yes
ExecStartPre=-/usr/bin/podman rm --ignore --force certbot
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/certbot.pid \\
	--hostname=certbot --name=certbot \\
	$ENV_PASS \\
	--systemd=false --log-opt=path=/dev/null \\
	--volume=letsencrypt:/etc/letsencrypt \\
	--volume=sockets:/var/run/sockets \\
	--pull=never --rm gongt/certbot
RestartPreventExitStatus=125 126 127 66
ExecStop=/usr/bin/podman stop -t 2 certbot
Restart=always
RestartSec=5

[Install]
WantedBy=machines.target

" > /usr/lib/systemd/system/certbot-dns.service

systemctl daemon-reload
systemctl enable certbot-dns.service
