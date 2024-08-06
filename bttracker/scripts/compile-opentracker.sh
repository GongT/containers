#!/usr/bin/env bash

set -Eeuo pipefail


group "=== build libowfat"
cd "$SOURCE/../libowfat"
LIBOWFAT_SOURCE=$(pwd)
make

group "=== build opentracker"
cd "$SOURCE"
export FEATURES="-DWANT_RESTRICT_STATS -DWANT_IP_FROM_QUERY_STRING -DWANT_IP_FROM_PROXY"

make "GIT_VERSION=$(date "+%Y-%m-%d-%H-%M-%S")" "LIBOWFAT_HEADERS=$LIBOWFAT_SOURCE" "LIBOWFAT_LIBRARY=$LIBOWFAT_SOURCE"

mkdir "$ARTIFACT_PREFIX/bin"
cp opentracker opentracker.debug "$ARTIFACT_PREFIX/bin"
chmod a+x "$ARTIFACT_PREFIX/bin"/*
