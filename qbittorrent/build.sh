#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE     f/force "force rebuild qbittorrent source code"
arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

BUILDER=$(create_if_not qbittorrent-build-worker fedora)
BUILDER_MNT=$(buildah mount $BUILDER)
info "init compile..."

if ! [[ -f "$BUILDER_MNT/usr/lib/golang/bin/go" ]] || [[ -n "$FORCE_DNF" ]]; then
	run_dnf $BUILDER $(<scripts/compile.lst)
	info "dnf install complete..."
else
	info "dnf install already complete."
fi

{
	SHELL_USE_PROXY
	cat scripts/prepare-golang.sh
} | buildah run $BUILDER bash
info "golang prepared..."

if [[ ! -e "$BUILDER_MNT/opt/dist/bin/qbittorrent" ]] || [[ -n "$FORCE" ]]; then
	mkdir -p "$BUILDER_MNT/opt/dist/usr/bin"
	for P in libtorrent qbittorrent; do
		info "build $P..."
		{
			SHELL_USE_PROXY
			echo "declare -r SOURCE='/opt/project'"
			echo "cd /opt/project"
			echo "declare -r ARTIFACT='/opt/dist/usr/bin'"
			echo "declare -r ARTIFACT_PREFIX='/opt/dist'"
			cat "scripts/build-$P.sh"
		} | buildah --mount "type=bind,src=$(pwd)/source/$P,target=/opt/project" run $BUILDER bash
		info "$P build complete..."
	done
else
	info "qbittorrent already built, skip..."
fi

RESULT=$(create_if_not "qbittorrent-result-worker" scratch)
RESULT_MNT=$(buildah mount $RESULT)
info "result image prepared..."

if [[ ! -e "$RESULT_MNT/usr/bin/bash" ]] || [[ -n "$FORCE_DNF" ]]; then
	run_dnf $RESULT $(<scripts/runtime.lst)
	buildah run $RESULT bash -c "rm -rf /etc/nginx /etc/privoxy"
	rm -rf "$RESULT_MNT/var/lib/dnf/" "$RESULT_MNT/var/cache/dnf/"
	info "dnf install complete..."
else
	info "dnf install already complete."
fi

buildah copy $RESULT fs /
buildah copy $RESULT "$BUILDER_MNT/opt/dist" /usr
info "result files copy complete..."

cat "scripts/prepare-run.sh" | buildah run $RESULT bash

buildah umount "$BUILDER" "$RESULT"

buildah config --cmd '/lib/systemd/systemd' "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/qbittorrent "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/qbittorrent
info "Done!"
