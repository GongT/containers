#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

for yaml_file in .github/workflows/generated-*yaml; do
	gh workflow run "$(basename "$yaml_file")" --ref master -f forceDnf=true
done
