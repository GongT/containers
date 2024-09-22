#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..


cp -f fs/etc/nginx/{conf.d}
