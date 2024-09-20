#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."

echo "::group::环境变量" >&2
env >&2
echo "::endgroup::" >&2

exec bash "${SOURCE_FILE}"
