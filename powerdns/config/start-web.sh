#!/bin/sh

set -ex

mkdir -p /run/sockets
rm -f /run/sockets/powerdns.sock

exec nginx
