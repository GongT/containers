#!/bin/sh

rm -rf /etc/nginx
mkdir -p /var/lib/nginx/logs /run/nginx
grep 'daily' /etc/crontabs/root | crontab -
