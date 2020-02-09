#!/bin/bash

function bind_mount() {
	local NAME=$1
	local P=$2

	mkdir -p "/data/AppData/$P"
	podman volume create --opt device=/data/AppData/$P --opt type=none --opt o=bind,nodev,noexec $NAME
}
function bind_share() {
	bind_mount $1 "share/$1"
}
function bind_data() {
	bind_mount $1 "data/$1"
}
bind_share sockets
bind_share letsencrypt
bind_data mariadb
bind_mount cloud /data/Volumes/AppData/NextCloud
bind_mount volumes /data/Volumes
