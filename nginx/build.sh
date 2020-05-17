#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild nginx source code"
arg_finish "$@"

info "starting..."

BUILDER=$(create_if_not nginx-build-worker fedora)
BUILDER_MNT=$(buildah mount $BUILDER)

info "init compile..."

if [[ ! -e "$BUILDER_MNT/opt/dist/usr/sbin/nginx" ]] || [[ -n "$FORCE" ]] ; then
	dev_dnf $BUILDER $(<requirements/build.lst)
	info "dnf install complete..."

    cat tools/build-nginx.sh | buildah run --volume "`pwd`/source:/opt/source" $BUILDER bash
    info "nginx build complete..."
else
    info "nginx already built, skip..."
fi

RESULT=$(new_container "nginx-result-worker" scratch)
RESULT_MNT=$(buildah mount $RESULT)
info "result image prepared..."

cp -r "$BUILDER_MNT/opt/dist/." "$RESULT_MNT"
cp    "tools/run-nginx.sh" "$RESULT_MNT/usr/sbin/nginx.sh"
cp    "tools/reload-nginx.sh" "$RESULT_MNT/usr/sbin/reload-nginx.sh"
cp    "tools/safe-reload.sh" "$RESULT_MNT/usr/bin/safe-reload"
chmod a+x "$RESULT_MNT/usr/sbin/nginx.sh" "$RESULT_MNT/usr/sbin/reload-nginx.sh" "$RESULT_MNT/usr/bin/safe-reload"
info "built content moved..."

cp -r config/. -t "$RESULT_MNT/etc/nginx"
for D in /config /var/log/nginx /run /tmp /config.auto /etc/letsencrypt /run/sockets ; do
	mkdir -p "${RESULT_MNT}${D}"
done
info "config files created..."

buildah umount "$BUILDER" "$RESULT"

buildah config --entrypoint '["/bin/bash"]' --cmd '/usr/sbin/nginx.sh' --env PATH="/bin:/usr/bin:/usr/sbin" \
	--port 80 --port 443 --port 80/udp --port 443/udp "$RESULT"
buildah config --volume /config --volume /etc/letsencrypt "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/nginx "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/nginx
info "Done!"
