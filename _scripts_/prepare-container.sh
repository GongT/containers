#!/bin/bash

tmpf=$(mktemp --tmpdir "XXXXXXXXXXXXX.txt")
env | grep -E '^GITHUB_.*=|^^RUNNER_.*=|^CI=' >"${tmpf}"

docker run --rm -d --env-file "${tmpf}" \
	-v "${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE}" -w "${GITHUB_WORKSPACE}" \
	"${GITHUB_WORKSPACE}:/var/cache" -e "SYSTEM_COMMON_CACHE=/var/cache" \
	fedora:latest sleep infinity
