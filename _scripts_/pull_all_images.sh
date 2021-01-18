#!/usr/bin/env bash

set +e

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || die "???"

export SKIP_REMOVE=yes
mapfile -t IMAGES < <(podman images | grep gongt/ | grep latest | awk '{print $1}')

SKIP_REMOVE=yes
for IMAGE in "${IMAGES[@]}"; do
	echo -e "\e[38;5;10m * pull image $IMAGE...\e[0m"
	bash ../common/tools/pull-image.sh "$IMAGE" always
done
