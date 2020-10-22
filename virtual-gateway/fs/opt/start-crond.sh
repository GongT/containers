#!/usr/bin/env bash

set -Eeuo pipefail

declare -A EXISTS=()
mapfile -t EXISTS_FILE < <(find /etc/periodic -type f)
for I in "${EXISTS_FILE[@]}"; do
	D="$(dirname "$I")"
	EXISTS[$D]="$D"
done
for I in "${EXISTS[@]}"; do
	grep "$I" </etc/crontabs/root >>/tmp/crontab
done

cat /tmp/crontab >/etc/crontabs/root
rm /tmp/crontab

/opt/wait-net/wait.sh

exec /usr/sbin/crond -f -d 6 -c /etc/crontabs
