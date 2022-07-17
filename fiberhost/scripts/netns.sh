#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

eval "$(systemctl cat fiberhost.pod.service | grep 'Environment=' | sed 's/Environment=//g')"

if [[ ${INTERFACE_NAME+found} != found ]] || [[ ${NET_NAMESPACE+found} != found ]]; then
	echo "INTERFACE_NAME=${INTERFACE_NAME-*not found*}"
	echo "NET_NAMESPACE=${NET_NAMESPACE-*not found*}"
	die "Invalid call"
fi

echo "Running command inside namespace '$NET_NAMESPACE', interface name: '$INTERFACE_NAME'"

export NET_NAMESPACE
export INTERFACE_NAME

case "${1:-}" in
'')
	ip netns exec "$NET_NAMESPACE" /usr/bin/env - "PATH=$PATH" "NET_NAMESPACE=$NET_NAMESPACE" "INTERFACE_NAME=$INTERFACE_NAME" "PS1=[$NET_NAMESPACE \W]# " bash --norc --noprofile
	;;
*)
	die "unknown command $1"
	;;
esac
