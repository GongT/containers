#!/usr/bin/env bash

set -Eeuo pipefail

rm -rf /etc/nginx

ensure_group users 100
ensure_user media_rw 100 100
