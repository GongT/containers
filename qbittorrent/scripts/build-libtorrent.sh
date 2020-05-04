#!/usr/bin/env bash

set -e
cd /opt/qbittorrent/libtorrent


./configure --prefix="$ARTIFACT" -C \
	--with-gnu-ld \
	--with-boost \
	--enable-shared \
	--disable-static \
	--enable-logging \
	--enable-dht \
	--enable-encryption \
	--enable-disk-stats \
	--disable-examples \
	--disable-tests \
	--enable-python-binding \
	--with-libiconv

make -j$(nproc)
make install
