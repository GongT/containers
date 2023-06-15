#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

for i in .github/workflows/generated-*yaml; do
	gh workflow run "$(basename "$i")" --ref master -f forceDnf=true
done
