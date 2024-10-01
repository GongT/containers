#!/usr/bin/env bash

MY_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function image_base() {
	local FN KIND
	buildah_cache_start "ghcr.io/gongt/systemd-base-image"
	dnf_use_environment

	printf "%s\n" "$@" | sort | uniq | while read -r KIND; do
		pushd "${MY_DIR}/${KIND}" &>/dev/null

		# shellcheck source=/dev/null
		source "$(pwd)/build-steps.sh"

		popd &>/dev/null
	done
}
