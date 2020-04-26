#!/usr/bin/env bash

set -Eeuo pipefail

IP=$(podman inspect "proxyclient" --format '{{.NetworkSettings.IPAddress}}')

echo "nameserver ${IP}" > /tmp/dnsmasq-resolv-proxy.conf
