#!/usr/bin/env bash

MY_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function image_base() {
	# buildah_cache_start "ghcr.io/gongt/systemd-base-image"
	__image_base_step base
	for KIND; do
		__image_base_step "${KIND}"
	done
}

function __image_base_step() {
	local KIND=$1

	pushd "${MY_DIR}/${KIND}" &>/dev/null

	# shellcheck source=/dev/null
	source "$(pwd)/build-steps.sh"

	popd &>/dev/null
}
