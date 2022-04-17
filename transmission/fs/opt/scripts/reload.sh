#!/usr/bin/env bash

set -Eeuo pipefail

bash /opt/_scripts/_reload.sh

touch /data/invalid

kill -s HUP "$(</opt/transmission.pid)"
