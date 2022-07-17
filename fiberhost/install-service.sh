#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

NET_NAMESPACE="fiberhostnetworknamespace"
arg_string NET_NAMESPACE networkns "network namespace to create"
arg_string + INTERFACE_NAME interfacename "fiber interface name"
arg_finish "$@"

START_SCRIPT=$(install_script scripts/create-fiber-namespace.sh)
STOP_SCRIPT=$(install_script scripts/delete-fiber-namespace.sh)

auto_create_pod_service_unit
unit_podman_image gongt/fiberhost
unit_unit Description "Fiber optical network host"
unit_depend network-online.target

unit_body Environment "INTERFACE_NAME=$INTERFACE_NAME NET_NAMESPACE=$NET_NAMESPACE"
unit_podman_arguments --env="INTERFACE_NAME=$INTERFACE_NAME" --env="NET_NAMESPACE=$NET_NAMESPACE"

# unit_body Restart always
unit_hook_stop "+/usr/bin/bash $STOP_SCRIPT"
unit_hook_start "+/usr/bin/bash $START_SCRIPT"

network_use_manual "--network=ns:/var/run/netns/$NET_NAMESPACE" --dns=127.0.0.1
systemd_slice_type infrastructure
add_network_privilege

unit_finish

install_binary scripts/netns.sh fiberhost-network-namespace
