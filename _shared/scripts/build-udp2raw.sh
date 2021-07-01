#!/usr/bin/env bash

set -Eeuo pipefail

make -j
cp udp2raw "$ARTIFACT_PREFIX"
