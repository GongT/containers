#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "./common/functions-install.sh"

arg_finish "$@"

copy_file --mode 0644 _scripts_/80-myregistry.conf /etc/containers/registries.conf.d/80-myregistry.conf
copy_file --mode 0755 _scripts_/git-hook-commit-msg.sh "$(pwd).git/hooks/commit-msg"

network_define_macvlan_interface "bridge0"
network_provide_pod gateway veth:bridge0 --mac-address=86:13:02:8F:76:2A --dns=127.0.0.1 --infra-name=gateway
systemctl daemon-reload
