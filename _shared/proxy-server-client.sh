#!/usr/bin/env bash

set -Eeuo pipefail

declare -r PCS_CACHE_BRANCH="proxy-cs-builder"

pushd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null
### 编译依赖项目
STEP="安装编译依赖"
DEPS=(bash gcc git make g++ musl-dev linux-headers)
make_base_image_by_apk "registry.gongt.me/gongt/init" "$PCS_CACHE_BRANCH" "${DEPS[@]}"
### 编译依赖项目 END

### 编译udp2raw
STEP="编译udp2raw"
download_and_build_github "$PCS_CACHE_BRANCH" udp2raw wangyu-/udp2raw-tunnel unified
### 编译udp2raw END

### 编译microsocks
STEP="编译microsocks"
download_and_build_github "$PCS_CACHE_BRANCH" microsocks rofl0r/microsocks master
### 编译microsocks END

declare -r PROXY_BUILT_IMAGE=$BUILDAH_LAST_IMAGE
popd &>/dev/null
