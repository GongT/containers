#!/usr/bin/env bash

set -Eeuo pipefail

IP=$(podman inspect "proxyclient" --format '{{.NetworkSettings.IPAddress}}')

echo "server=${IP}" > /etc/dnsmasq.d/dnsmasq-resolv-proxy.conf
