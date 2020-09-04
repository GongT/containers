#!/bin/sh

set -e

cd /mnt

[ -d lib ] && rmdir lib
[ -L lib ] && rm lib

mv lib64 lib

cp -fa -- * /
