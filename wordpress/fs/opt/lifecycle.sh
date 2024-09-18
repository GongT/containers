#!/bin/sh

PROJ=wordpress

apply_gateway() {
	local F=$1 T="/run/nginx/config/vhost.d/${PROJ}.conf"
	if [ -z "$F" ] ; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	echo 'GET /' | nc local:/run/sockets/nginx.reload.sock
}

apply_gateway bridge

trap 'echo "will shutdown"' INT

if ! [ -e /data/config/salt.php ] ; then
	mkdir -p /data/config
	sleep 3 # wait network
	echo '<?php
$salt = file_get_contents("https://api.wordpress.org/secret-key/1.1/salt/");
echo("---------------------------\n");
echo($salt);
echo("---------------------------\n");
file_put_contents("/data/config/salt.php", "<?php\n".$salt);
' | php
fi

echo "sleep."
sleep infinity &
wait $!

echo "wakeup."

rm -vf /run/sockets/word-press.sock

apply_gateway down

echo "byebye."
