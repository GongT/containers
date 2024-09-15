#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

bash "${SOURCE_FILE}" || die "Build failed"
