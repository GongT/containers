#!/usr/bin/env bash

set -e

./bootstrap.sh --prefix="$ARTIFACT_PREFIX" -C \
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


# new version 
exit 0

mkdir -p build
cd build

export BOOST_LIBRARYDIR=/usr/local/lib
cmake .. \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_CXX_STANDARD=17 \
	-Dpython-bindings=ON \
	-Dwebtorrent=ON \
	-DCMAKE_INSTALL_PREFIX:PATH="$ARTIFACT_PREFIX"

cmake --build . --target install --config Release --parallel $(nproc)
