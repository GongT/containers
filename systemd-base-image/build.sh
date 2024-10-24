#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

buildah_cache_start "quay.io/fedora/fedora-minimal"
dnf_use_environment
dnf_install_step "systemd" scripts/dependencies.lst

setup_systemd "systemd" basic

buildah_finalize_image "systemd" gongt/systemd-base-image
