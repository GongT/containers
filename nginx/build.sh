#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

FORCE=
function check_args() {
    while [[ $# -gt 0 ]]; do
        local K=$1
        shift
        case "$K" in
            -f)
                FORCE=true
            ;;
            --)
                return
            ;;
            *)
                die "Unknown argument: $K"
        esac
        shift
    done
}
check_args $(getopt -o f -- "$@")

info "starting..."

BUILDER=$(create_if_not nginx-build-worker fedora)
BUILDER_MNT=$(buildah mount $BUILDER)

info "init compile..."

buildah run $BUILDER dnf install --setopt=max_parallel_downloads=10 -y $(<requirements/build.lst)
info "dnf install complete..."

if [[ ! -e "$BUILDER_MNT/opt/dist/usr/sbin/nginx" ]] || [[ -n "$FORCE" ]] ; then
    buildah copy $BUILDER source "/opt/source"
    cat tools/build-nginx.sh | buildah run $BUILDER bash
    info "nginx build complete..."
else
    info "nginx already built, skip..."
fi

RESULT_NAME=nginx-result-worker
EXISTS=$(buildah inspect --type container --format '{{.Container}}' "$RESULT_NAME" || true)
if [[ -n "$EXISTS" ]]; then
    buildah rm "$EXISTS"
    info "previous result removed..."
fi
RESULT=$(buildah from --name "$RESULT_NAME" scratch)

RESULT_MNT=$(buildah mount $RESULT)
info "result image prepared..."

cp -r "$BUILDER_MNT/opt/dist/." "$RESULT_MNT"
cp    "tools/run-nginx.sh" "$RESULT_MNT/usr/sbin/nginx.sh"
chmod a+x "$RESULT_MNT/usr/sbin/nginx.sh"
info "built content moved..."

mkdir -p "$RESULT_MNT/etc/nginx"
cp -r config/* "$RESULT_MNT/etc/nginx"
info "config files created..."

buildah umount "$BUILDER" "$RESULT"

buildah config --entrypoint '["/usr/bin/bash"]' --cmd '/usr/sbin/nginx.sh' --env PATH="/usr/bin:/usr/sbin" --port 80 --port 443 "$RESULT"
buildah config --volume /config --volume /etc/letsencrypt --volume /wellknown "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/nginx "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/nginx
info "Done!"
