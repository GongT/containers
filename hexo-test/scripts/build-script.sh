#!/bin/sh

set -e

echo "nameserver 10.0.0.1" > /etc/resolv.conf

if ! command -v pnpm &>/dev/null ; then
	apk add nodejs git
	wget -O - https://unpkg.com/@pnpm/self-installer | node
fi
if ! command -v hexo &>/dev/null ; then
	pnpm install -g hexo-cli
fi

if ! [[ -e "/data/app/_config.yml" ]] ; then
	rm -rf /data/app
	hexo init /data/app --no-install
fi

cd /data/app
# pnpm install --store-dir /data/store
pnpm --store-dir /data/store add \
	hexo-admin serve-static body-parser
