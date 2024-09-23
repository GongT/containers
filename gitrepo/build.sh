#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start "ghcr.io/gongt/systemd-base-image"
dnf_use_environment
dnf_install_step "gitrepo" scripts/requirements.lst

merge_local_fs "gitrepo"

setup_systemd "gitrepo" \
	enable "REQUIRE=fcgiwrap.service" \
	nginx_attach

buildah_finalize_image gitrepo gongt/gitrepo
info_log "Done."
