#!/usr/bin/env bash

set -Eeuo pipefail

rm -rf /etc/nginx

function ensure_user() {
	local U_ID=$1 U_NAME=$2 G_ID=$3
	if cat /etc/passwd | grep -- "$U_NAME" | grep -q -- ":$U_ID:$G_ID:"; then
		echo "Group $U_NAME exists with id $U_ID"
	else
		useradd --gid "$G_ID" --no-create-home --no-user-group --uid "$U_ID" "$U_NAME"
		echo "Created $U_NAME."
	fi
}

function ensure_group() {
	local G_ID=$1 G_NAME=$2
	if cat /etc/group | grep -- "$G_NAME" | grep -q -- ":$G_ID:"; then
		echo "Group $G_NAME exists with id $G_ID"
	else
		groupadd -g "$G_ID" "$G_NAME"
		echo "Created $G_NAME."
	fi
}

ensure_group 100 users
ensure_user 100 media_rw 100
