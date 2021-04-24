#!/usr/bin/env bash

export CXXFLAGS+=-std=c++14

./bootstrap.sh --prefix="$ARTIFACT_PREFIX" \
	--disable-silent-rules \
	--with-gnu-ld \
	--disable-rpath \
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
# --enable-TORRENT_NO_DEPRECATE \
# CXXFLAGS=-std=c++14

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
