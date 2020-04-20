#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

WORK=$(create_if_not work-gfw-worker gongt/alpine-init:latest-cn)
RESULT=$(create_if_not work-gfw-result gongt/alpine-init:latest-cn)

info "init compile..."

buildah run $RESULT apk --no-cache add wireguard-tools-wg unbound bash
MNT=$(buildah mount $RESULT)

# build microsocks
info " * microsocks"
buildah run $WORK apk --no-cache add make gcc musl-dev
buildah unmount $WORK
MNT_WORK=$(buildah mount $WORK)

buildah copy $WORK microsocks/ /build
buildah run $WORK sh -c "cd /build && make"
cp "${MNT_WORK}/build/microsocks" "${MNT}/usr/bin/microsocks"
chmod 0777 "${MNT}/usr/bin/microsocks"

# copy udp2raw
info " * udp2raw"
if [[ ! -e ".download/udp2raw_amd64_hw_aes" ]]; then
	info "    downloading..."
	exit 1
fi
cp ".download/udp2raw_amd64_hw_aes" "${MNT}/usr/bin/udp2raw"
chmod 0777 "${MNT}/usr/bin/udp2raw"

# copy ssh key
info " * ssh-keys"
mkdir -p "${MNT}/root/.ssh"
cp "$HOME/.ssh/private/router.rsa" "${MNT}/root/.ssh/id_rsa"
chmod 0600 "${MNT}/root/.ssh/id_rsa"

# copy config files
info " * config files"
buildah unmount $RESULT
buildah copy $RESULT fs /

info "files ok."

buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/proxyserver-nat "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/proxyserver-nat
info "Done!"
