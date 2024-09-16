#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + CF_TOKEN token "cloudflare api token"
arg_string + CF_ZONE_ID zone "cloudflare dns zone"
arg_string + CF_RECORD_ID4 4 "record id"
arg_string + CF_RECORD_ID6 6 "record id"
arg_string + HOST_NAME h/host "full domain name"
arg_finish "$@"

create_pod_service_unit gateway-network
unit_podman_image gongt/gateway-network
unit_unit Description virtual machine gateway
unit_unit After network-online.target

# unit_body Restart no
# unit_podman_image_pull never

network_use_pod gateway
systemd_slice_type infrastructure

add_network_privilege

unit_podman_safe_environment \
	"CF_TOKEN=${CF_TOKEN}" \
	"CF_ZONE_ID=${CF_ZONE_ID}" \
	"CF_RECORD_ID4=${CF_RECORD_ID4}" \
	"CF_RECORD_ID6=${CF_RECORD_ID6}" \
	"HOST_NAME=${HOST_NAME}"
unit_fs_bind data/gateway-network /storage

unit_finish
