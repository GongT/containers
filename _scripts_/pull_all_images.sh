#!/usr/bin/env bash

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || die "???"

if [[ "${HTTP_PROXY:-}" ]]; then
	echo -e "\e[38;5;14mUsing proxy $HTTP_PROXY\e[0m" >&2
	unset http_proxy https_proxy all_proxy
	export HTTPS_PROXY="$HTTP_PROXY" ALL_PROXY="$HTTP_PROXY"
else
	unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
	echo -e "\e[38;5;14mUsing direct connection\e[0m" >&2
fi

export SKIP_REMOVE=yes
IMAGES=()

if [[ $# -eq 0 ]]; then
	mapfile -t IMAGES < <(podman images | grep gongt/ | grep latest | awk '{print $1}')
else
	for IMAGE in "${@}"; do
		IMAGES+=("docker.io/gongt/$IMAGE")
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
	bash ../common/tools/pull-image.sh "$IMAGE" always || {
		echo -e "\e[38;5;9mFailed pull image $IMAGE\e[0m" >&2
	}
done
