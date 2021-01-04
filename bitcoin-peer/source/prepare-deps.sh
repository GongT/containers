#!/usr/bin/env bash

set -Eeuo pipefail

collect_dist_binary_dependencies

copy_collected_dependencies

cd "$INSTALL_TARGET"
mkdir data
chattr +i data
