#!/bin/sh

set -e

export PATH="$(pwd):$PATH"
echo "PATH=$PATH"
make -j

install -m 0755 udp2raw /usr/bin/udp2raw
