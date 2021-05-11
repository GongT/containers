#!/usr/bin/env bash

set -Eeuo pipefail

rm -rf /etc/crontabs /etc/periodic
mkdir /etc/crontabs
touch /etc/crontabs/root /root/.bashrc

cd /opt/acme.sh.source
bash acme.sh --install \
	--home /opt/acme.sh \
	--config-home "/etc/letsencrypt/acme.sh" \
	--accountemail "admin@example.com" \
	--accountkey /etc/letsencrypt/acme.sh/account.key \
	--accountconf /etc/letsencrypt/acme.sh/account.conf
