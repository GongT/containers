#!/usr/bin/env bash

set -Eeuo pipefail

export BUILDAH_HISTORY=true

# Create a example base image
# CONTAINER=$(buildah from scratch)
# MNT=$(buildah mount "$CONTAINER")
# dd if=/dev/random of="$MNT/TEST_FILE" bs=1M count=1
# buildah umount "$CONTAINER" > /dev/null
# LAST_IMG=$(buildah commit --rm "$CONTAINER" my-test:base 2> /dev/null)
# Or use some existing
LAST_IMG="alpine"

for i in $(seq 1 5); do
	echo "loop: $i, size: $(podman inspect --type=image --format '{{.Size}}' "$LAST_IMG")"

	CONTAINER=$(buildah from "$LAST_IMG")
	buildah config --label="test=$i" --created-by="step $i" "$CONTAINER"
	LAST_IMG=$(buildah commit --rm "$CONTAINER" my-test:$i 2> /dev/null)

done
echo "final: $(podman inspect --type=image --format '{{.Size}}' "$LAST_IMG")"
