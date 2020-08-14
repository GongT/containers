#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

RESULT=$(create_if_not gfw-client-result alpine:latest)

info "init compile..."

buildah run $(use_alpine_apk_cache) $RESULT apk add bash wireguard-tools-wg dnsmasq privoxy
MNT=$(buildah mount $RESULT)

rm -rf "$MNT/etc/nginx" "$MNT/etc/dnsmasq.conf" "$MNT/etc/dnsmasq.d" "$MNT/etc/privoxy"

# copy udp2raw
info " * udp2raw"
load_shared_project udp2raw
build_udp2raw
copy_dist_program $RESULT

# copy config files
info " * config files"
buildah unmount $RESULT
buildah copy $RESULT fs /

info "files ok."

buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/proxyclient "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/proxyclient
info "Done!"
