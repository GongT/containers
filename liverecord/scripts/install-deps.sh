#!/usr/bin/env bash

set -Eeuo pipefail
set -x

# -oDebug::pkgAcquire::Worker=1
apt update
apt install -y --no-install-recommends python3 ffmpeg
