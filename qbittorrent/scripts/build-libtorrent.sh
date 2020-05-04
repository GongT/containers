#!/usr/bin/env bash

set -e

./bootstrap.sh
./configure --prefix="$ARTIFACT_PREFIX" -C \
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
