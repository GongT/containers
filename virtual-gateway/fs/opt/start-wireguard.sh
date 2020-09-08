#!/bin/bash

set -a
source /etc/wireguard/client.conf

/usr/libexec/wireguard-config-client
