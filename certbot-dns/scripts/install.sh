#!/usr/bin/env bash

set -Eeuo pipefail

cd /opt/acme.sh
bash acme.sh --install \
	--home /usr/bin \
	--config-home "/etc/letsencrypt/acme.sh" \
	--accountemail "admin@example.com" \
	--accountkey /etc/letsencrypt/acme.sh/account.key \
	--accountconf /etc/letsencrypt/acme.sh/account.conf \
	--nocron \
	--noprofile

echo "
# min   hour    day     month   weekday command
0       3       *       *       1       run-parts /etc/periodic/weekly
" >/etc/crontabs/root

mkdir -p /etc/periodic/20day
