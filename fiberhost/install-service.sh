#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

NET_NAMESPACE="fiberhostnetworknamespace"
arg_string   NET_NAMESPACE interfacename "fiber interface name"
arg_string + INTERFACE_NAME interfacename "fiber interface name"
arg_finish "$@"

install_script scripts/create-fiber-namespace.sh START_SCRIPT
install_script scripts/delete-fiber-namespace.sh STOP_SCRIPT

auto_create_pod_service_unit
unit_podman_image gongt/fiberhost
unit_unit Description "Fiber optical network host"
unit_depend network-online.target

unit_body Environment "INTERFACE_NAME=$INTERFACE_NAME NET_NAMESPACE=$NET_NAMESPACE"
unit_podman_arguments --env="INTERFACE_NAME=$INTERFACE_NAME" --env="NET_NAMESPACE=$NET_NAMESPACE"

unit_body Restart always
unit_hook_stop "+/usr/bin/bash $STOP_SCRIPT"
unit_hook_start "+/usr/bin/bash $START_SCRIPT"
network_use_manual "--network=ns:/var/run/netns/$NET_NAMESPACE"
unit_finish
