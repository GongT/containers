#!/usr/bin/env bash

set -Eeuo pipefail

make -j
install -D -m 0755 microsocks "$ARTIFACT_PREFIX/usr/bin/microsocks"
