#!/usr/bin/env bash

export PKG_CONFIG_PATH="$ARTIFACT_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="$CPPFLAGS -I/usr/include/qt5"

ldconfig

pkg-config --list-all | grep torrent

make distclean || true

./bootstrap.sh
./configure --prefix="$ARTIFACT_PREFIX" \
	--enable-TORRENT_NO_DEPRECATE \
	--with-boost \
	CXXFLAGS=-std=c++14

make -j$(nproc)
make install
