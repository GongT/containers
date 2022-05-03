#!/usr/bin/env bash

set -Eeuo pipefail

export UIPORT=$RANDOM

exec /usr/sbin/init
