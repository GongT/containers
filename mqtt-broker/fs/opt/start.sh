#!/usr/bin/env bash

set -Eeuo pipefail

rm -f /run/sockets/mqtt.sock

bash /opt/nginx-control.sh start

PASSWD=$(echo $RANDOM | md5sum | awk '{print $1}')

mosquitto_passwd -c -b /etc/mosquitto/passwords admin "$PASSWD"
echo "--pw $PASSWD" >>/etc/mosquitto/client.conf

mosquitto_passwd -b /etc/mosquitto/passwords "$USERNAME" "$PASSWORD"

exec mosquitto --config-file /etc/mosquitto/mosquitto.conf
