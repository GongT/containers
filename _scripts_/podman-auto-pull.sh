#!/usr/bin/env bash

set -Eeuo pipefail

podman images --format '{{.Repository}}:{{.Tag}}' \
	| grep -v "<none>" \
	| grep -v "localhost/" \
	| grep -v "example.com/" \
	| xargs --no-run-if-empty -n1 -t -IF bash -c "podman pull F ; exit 0"

podman images | grep -E '<none>' | awk '{print $3}' | xargs --no-run-if-empty -t --no-run-if-empty podman rmi || true
podman images | grep -E 'localhost/' | awk '{print $3}' | xargs --no-run-if-empty -t --no-run-if-empty podman rmi || true
