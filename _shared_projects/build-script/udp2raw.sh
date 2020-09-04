#!/usr/bin/env bash

set -Eeuo pipefail

WORK=$(create_if_not build_udp2raw_worker alpine)
buildah run $(use_alpine_apk_cache) "$WORK" apk add -U make gcc musl-dev g++ linux-headers

## no .git folder exists in container, hack here
GIT_VER=$(cd "$PROJECT_ROOT" && git rev-parse HEAD)
cat <<- EOF > "$PROJECT_ROOT/git"
	#!/bin/sh
	echo '$GIT_VER'
EOF
chmod a+x "$PROJECT_ROOT/git"

cat <<- 'EOF' | buildah run "$MOUNT_INSTALL_TARGET" "$MOUNT_BUILD_SOURCE" "$WORK" sh
	set -e

	if ! [ -e "/udp2raw" ]; then
		export PATH="/build:$PATH"
		echo "PATH=$PATH"
		cd /build
		make -j
		mv udp2raw /udp2raw
	fi
	install -m 0755 /udp2raw /install/usr/bin/udp2raw
EOF
