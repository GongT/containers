#!/usr/bin/env bash

set -Eeuo pipefail
set -x

echo 'Acquire::Retries "100";' > /etc/apt/apt.conf.d/80-retries
sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
# -oDebug::pkgAcquire::Worker=1
apt update
apt install -y --no-install-recommends ffmpeg jq nginx curl
