#!/usr/bin/env bash

set -Eeo pipefail

cd /

if [[ ${DEBUG} == "yes" ]]; then
	exec /bin/opentracker.debug -f /etc/config
else
	exec /bin/opentracker -f /etc/config
fi
