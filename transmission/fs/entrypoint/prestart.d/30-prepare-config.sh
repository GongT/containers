#!/usr/bin/env bash

set -Eeuo pipefail

chmod a+w /var/run

# /opt/config 是挂载的配置文件目录，其中包含多个instance的配置文件
# /opt/scripts/config.json 是编进容器的通用模板

if ! [[ -f "/opt/config/$INSTANCE_NAME.json" ]]; then
	echo "{}" >"/opt/config/$INSTANCE_NAME.json"
fi

if [[ -f /opt/data/settings.json ]]; then
	unlink /opt/data/settings.json
fi

sed "s/{instance}/$INSTANCE_NAME/g" </opt/scripts/config.json >/tmp/config.json

jq -s '.[0] * .[1]' /tmp/config.json "/opt/config/$INSTANCE_NAME.json" >/opt/data/settings.json

sed "s/{instance}/$INSTANCE_NAME/g" </opt/scripts/nginx.template.conf >"/opt/nginx.attach.conf"

chown -R media_rw:users /opt
