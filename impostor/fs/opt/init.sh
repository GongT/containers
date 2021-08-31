#!/usr/bin/env bash

set -Eeuo pipefail

cd /app
mkdir -p /data/plugins /data/libraries

ln -s /data/plugins ./
ln -s /data/libraries ./

if [[ ! -f /data/certs/certificate.pem ]]; then
	mkdir -p /data/certs
	openssl req -x509 -newkey rsa:2048 -keyout /data/certs/key.pem -out /data/certs/certificate.pem -days 3650 -nodes \
		-subj "/C=CN/ST=Beijing/L=Beijing/O=something/CN=www.gongt.me"
fi

exec ./Impostor.Server
