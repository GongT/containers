#!/bin/sh

set -ex

mkdir -p /var/run/sockets
rm -f /var/run/sockets/powerdns.sock

exec nginx
