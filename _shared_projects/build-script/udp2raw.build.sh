#!/bin/sh

set -e

export PATH="$(pwd):$PATH"
echo "PATH=$PATH"
make -j
