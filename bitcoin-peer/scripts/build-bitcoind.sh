#!/bin/bash

./autogen.sh
./configure CXX=clang++ CC=clang --config-cache \
	--prefix="/usr" \
	--disable-bench \
	--disable-tests \
	--disable-wallet \
	--enable-util-cli \
	--enable-util-wallet \
	--with-miniupnpc=no \
	--without-qrencode \
	--without-libs \
	--with-daemon \
	--without-gui \
	--with-boost \
	--enable-hardening

make -j
make "DESTDIR=$ARTIFACT_PREFIX" install
