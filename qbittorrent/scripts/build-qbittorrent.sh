#!/usr/bin/env bash

set -e
cd /opt/qbittorrent/source


export PKG_CONFIG_PATH="/opt/qbittorrent/libtorrent-dist/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="$CPPFLAGS -I/usr/include/qt5"

ldconfig

./configure --prefix="$ARTIFACT" -C \
	--with-boost

make -j$(nproc)
make install
