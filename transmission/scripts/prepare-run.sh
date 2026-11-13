#!/usr/bin/env bash

set -Eeuo pipefail

ensure_group users 100
ensure_user media_rw 100 100

mkdir -p /home/media_rw
chown media_rw:users /home/media_rw

mkdir -p /root/.config
touch /root/.config/user-dirs.dirs

# 删除默认的 transmission-daemon 单元文件，需要修改的太多不如直接自己写
systemctl disable transmission-daemon.service
unlink /usr/lib/systemd/system/transmission-daemon.service
