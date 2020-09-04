#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

WORK=$(create_if_not work-gfw-worker gongt/alpine-init)
RESULT=$(create_if_not work-gfw-result gongt/alpine-init)

info "init compile..."

buildah run $(use_alpine_apk_cache) $RESULT apk add wireguard-tools-wg bash dnsmasq privoxy nmap-ncat curl
MNT=$(buildah mount $RESULT)
rm -rf "$MNT/etc/dnsmasq.conf" "$MNT/etc/dnsmasq.d"

# build microsocks
info " * microsocks"
buildah run $(use_alpine_apk_cache) $WORK apk add make gcc musl-dev
buildah unmount $WORK
MNT_WORK=$(buildah mount $WORK)

buildah copy $WORK microsocks/ /build
buildah run $WORK sh -c "cd /build && make"
install -T "${MNT_WORK}/build/microsocks" "${MNT}/usr/bin/microsocks"

# build udp2raw
install_shared_project udp2raw "$MNT" 

# copy config files
info " * config files"
buildah unmount $RESULT
buildah copy $RESULT fs /

info "files ok."

buildah config --entrypoint='["/bin/bash"]' --cmd '/opt/init.sh' "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/proxyserver-nat "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/proxyserver-nat
info "Done!"
