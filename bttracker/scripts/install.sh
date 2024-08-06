#!/usr/bin/env bash

set -Eeuo pipefail

cd "$INSTALL_SOURCE"
ls -l bin
mkdir "$INSTALL_TARGET/bin"
cp opentracker opentracker.debug "$INSTALL_TARGET/bin"

collect_dist_root
