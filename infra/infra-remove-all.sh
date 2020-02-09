#!/usr/bin/env bash

podman ps -a | tail -n +2 | grep -v Up | awk '{print $1}' \
	| xargs --no-run-if-empty --verbose --no-run-if-empty podman rm
