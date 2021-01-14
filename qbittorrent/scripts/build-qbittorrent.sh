#!/usr/bin/env bash

export PKG_CONFIG_PATH="$ARTIFACT_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CPPFLAGS="${CPPFLAGS:-} -I/usr/include/qt5"
export LDFLAGS="${LDFLAGS:-} -lpthread"

ldconfig

function die() {
	echo "$*" >&2
	exit 1
}

pkg-config --list-all | grep libtorrent-rasterbar || die "pkg-config did not list libtorrent-rasterbar"

cmake -B build -DCMAKE_BUILD_TYPE=Release "-DCMAKE_INSTALL_PREFIX=$ARTIFACT_PREFIX"
cmake --build build --parallel --clean-first
cmake --install build
