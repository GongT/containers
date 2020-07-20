#!/bin/bash

if [[ -z "$ipv6" ]] ; then
	exit 0
fi

cd /storage
DEV=wg0 \
	bash -Exeuo pipefail \
	wg0.conf

echo "wireguard setup complete."

# exec sleep infinity - standalone
