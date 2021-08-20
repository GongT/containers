#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p config/net.mamoe.mirai-api-http
cp http-plugin-setting.yaml config/net.mamoe.mirai-api-http/setting.yml

exec java -Dfile.encoding=UTF-8 -jar mcl.jar
