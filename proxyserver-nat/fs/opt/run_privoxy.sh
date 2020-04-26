#!/bin/bash

rm -f /tmp/logfile
mkfifo /tmp/logfile
chmod 0777 /tmp/logfile
cat /tmp/logfile &

exec /usr/sbin/privoxy --no-daemon /etc/privoxy/config
