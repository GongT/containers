#!/usr/bin/env bash

set -Eeuo pipefail

cd /usr/share/nextcloud

set -a
source /run/.userenvironments

exec php -d memory_limit=2G occ "$@"
