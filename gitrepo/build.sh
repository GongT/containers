#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start "ghcr.io/gongt/systemd-base-image"
dnf_use_environment
dnf_install_step "gitrepo" scripts/requirements.lst

setup_systemd \
	enable "REQUIRE=fcgiwrap.socket" \
	nginx_attach

merge_local_fs "gitrepo"

buildah_finalize_image gitrepo gongt/gitrepo
info_log "Done."
