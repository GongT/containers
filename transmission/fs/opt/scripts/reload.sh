#!/usr/bin/env bash

set -Eeuo pipefail

bash /opt/scripts/_reload.sh

touch /data/invalid

kill -s HUP "$(</opt/transmission.pid)"
