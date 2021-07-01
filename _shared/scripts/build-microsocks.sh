#!/usr/bin/env bash

set -Eeuo pipefail

make -j
cp microsocks "$ARTIFACT_PREFIX"
