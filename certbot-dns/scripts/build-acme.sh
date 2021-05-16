#!/usr/bin/env bash

set -Eeuo pipefail

rm -rf /etc/crontabs /etc/periodic
mkdir /etc/crontabs
touch /etc/crontabs/root /root/.bashrc

bash acme.sh --install \
	--home /opt/acme.sh \
	--config-home "/opt/data" \
	--accountemail "admin@example.com" \
	--accountkey "/opt/data/account.key" \
	--accountconf "/opt/data/account.conf"
