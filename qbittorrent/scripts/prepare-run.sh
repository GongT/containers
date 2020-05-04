#!/usr/bin/env bash



cd /opt/qBittorrent

chown media_rw . -R

[[ -L config ]] && unlink config
[[ -e config ]] && rm -rf config
ln -s /mnt/config

localectl set-locale zh_CN.UTF-8

# chown media_rw /mnt/config -R
