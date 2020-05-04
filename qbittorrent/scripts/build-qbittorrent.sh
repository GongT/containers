#!/usr/bin/env bash

set -e

export PKG_CONFIG_PATH="$ARTIFACT_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="$CPPFLAGS -I/usr/include/qt5"

ldconfig

./configure --prefix="$ARTIFACT_PREFIX" -C \
	--with-boost

make -j$(nproc)
make install
