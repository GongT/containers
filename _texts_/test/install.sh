#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../../common/functions-install.sh

create_unit gongt/test
# unit_start_notify sleep 4
# unit_start_notify output "4:"
unit_start_notify touch
unit_fs_tempfs 512M /tmp
unit_finish
