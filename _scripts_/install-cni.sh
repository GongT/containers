#!/usr/bin/env bash

set -Eeuo pipefail

cd /tmp
wget --continue 'https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz' -O cni-v111.tgz
mkdir -p /opt/cni/bin
tar -xf cni-v111.tgz -C /opt/cni/bin

ls -l /opt/cni/bin
