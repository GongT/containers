#!/usr/bin/env bash

set -Eeuo pipefail

### 编译udp2raw
STEP="安装udp2raw编译依赖"
DEPS=(bash make gcc musl-dev g++ linux-headers)
make_base_image_by_apk "alpine" "udp2raw" "${DEPS[@]}"

## no .git folder exists in container, hack here
GIT_VER=$(cd "$PROJECT_ROOT" && git rev-parse HEAD)
echo "#!/bin/sh
	echo '$GIT_VER'
" >"$PROJECT_ROOT/git"
chmod a+x "$PROJECT_ROOT/git"

SCRIPT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/udp2raw.build.sh"

__hash_udp2raw() {
	echo "$GIT_VER"
	cat "$SCRIPT"
}
__compile_udp2raw() {
	local BUILDER="$1"
	run_compile udp2raw "$BUILDER" "$SCRIPT"
}
STEP="编译udp2raw"
buildah_cache2 "udp2raw" __hash_udp2raw __compile_udp2raw

STEP="复制udp2raw"
run_install udp2raw "$BUILDAH_LAST_IMAGE" "$COMPILE_TARGET_DIRECTORY" <<-'INSTALL'
	install -m 0755 /usr/bin/udp2raw "$INSTALL_TARGET/"
INSTALL
