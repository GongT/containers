#!/usr/bin/env bash

CFG=${1-/etc/nginx/nginx.conf}

link-effective main
config-file-macro /etc/nginx
nginx -t -c "${CFG}"
