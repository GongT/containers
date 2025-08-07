#!/usr/bin/env bash

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || die "???"

unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY

export SKIP_REMOVE=yes
IMAGES=()

function add_to_set() {
	local IMAGE=$1
	if [[ " ${IMAGES[*]} " != *" ${IMAGE} "* ]]; then
		IMAGES+=("${IMAGE}")
	fi
}

if [[ $# -eq 0 ]]; then
	mapfile -t _IMAGES < <(podman images | grep gongt/ | grep latest | awk '{print $1}')
	for I in "${_IMAGES[@]}"; do
		add_to_set "${I#*\/}"
	done
else
	for IMAGE in "${@}"; do
		if [[ $IMAGE != gongt/* ]]; then
			IMAGE="gongt/$IMAGE"
		fi
		add_to_set "$IMAGE"
	done
fi

EXIT=
trap 'EXIT=1; exit 0' INT

SKIP_REMOVE=yes
for IMAGE in "${IMAGES[@]}"; do
	if [[ "$EXIT" ]]; then
		exit 0
	fi
	echo -e "\e[38;5;10m * pull image $IMAGE...\e[0m"
	bash ../common/tools/pull-image.sh "registry.gongt.me/$IMAGE" always || {
		echo -e "\e[38;5;9mFailed pull image $IMAGE\e[0m" >&2
	}
done
