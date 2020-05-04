#!/usr/bin/env bash

set -e

chown -R media_rw:users /opt/qBittorrent

if [[ -e /opt/qBittorrent/config/qBittorrent.conf ]]; then
	exit 0
fi

echo "first run."
mkdir -p /opt/qBittorrent/config
cp /opt/scripts/qBittorrent.conf /opt/qBittorrent/config/qBittorrent.conf
