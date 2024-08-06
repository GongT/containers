#!/usr/bin/env bash

set -Eeo pipefail

cd /

if [[ ${DEBUG} == "yes" ]]; then
	/bin/opentracker.debug -f /opt/config
else
	/bin/opentracker -f /opt/config
fi

echo "::load:complete::"
