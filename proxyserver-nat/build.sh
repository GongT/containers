#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

WORK=$(create_if_not work-gfw-worker gongt/alpine-init:latest-cn)
RESULT=$(create_if_not work-gfw-result gongt/alpine-init:latest-cn)

info "init compile..."

buildah run $RESULT apk --no-cache add wireguard-tools-wg bash dnsmasq privoxy nmap-ncat curl
MNT=$(buildah mount $RESULT)
rm -rf "$MNT/etc/dnsmasq.conf" "$MNT/etc/dnsmasq.d"

# build microsocks
info " * microsocks"
buildah run $WORK apk --no-cache add make gcc musl-dev
buildah unmount $WORK
MNT_WORK=$(buildah mount $WORK)

buildah copy $WORK microsocks/ /build
buildah run $WORK sh -c "cd /build && make"
cp "${MNT_WORK}/build/microsocks" "${MNT}/usr/bin/microsocks"
chmod 0777 "${MNT}/usr/bin/microsocks"

# build udp2raw
info " * udp2raw"
load_shared_project udp2raw
build_udp2raw
copy_dist_program $RESULT

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
