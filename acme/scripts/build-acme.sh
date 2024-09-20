#!/usr/bin/env bash

set -Eeuo pipefail

cd /mnt
echo "Install acme.sh!"

bash acme.sh --install --nocron --no-profile \
	--home /opt/acme.sh \
	--config-home "/opt/data" \
	--accountemail "admin@example.com" \
	--accountkey "/opt/data/account.key" \
	--accountconf "/opt/data/account.conf"
