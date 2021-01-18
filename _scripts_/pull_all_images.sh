#!/usr/bin/env bash

set +e

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || die "???"

export SKIP_REMOVE=yes
mapfile -t IMAGES < <(podman images | grep gongt/ | grep latest | awk '{print $1}')

for IMAGE in "${IMAGES[@]}"; do
	echo "* pull image $IMAGE..."
	bash ../common/tools/pull-image.sh "$IMAGE" always
done
