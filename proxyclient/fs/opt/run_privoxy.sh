#!/bin/bash

if [[ ! -e /config/default.action ]]; then
	echo '{+forward-override{forward  .} \
}
' > /config/default.action
fi

rm -f /tmp/logfile
mkfifo /tmp/logfile
chmod 0777 /tmp/logfile
cat /tmp/logfile &

exec /usr/sbin/privoxy --no-daemon /etc/privoxy/config
