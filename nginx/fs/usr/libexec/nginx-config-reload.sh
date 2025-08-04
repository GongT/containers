#!/usr/bin/bash

export PATH=/usr/local/bin:/usr/local/bin:/usr/bin:/usr/bin:/bin:/bin:/usr/xbin

link-effective main
config-file-macro /etc/nginx

if DATA=$(nginx -t 2>&1); then
	echo "========================="
	echo "== config test success =="
	echo "========================="
	nginx -s reload
else
	echo "========================"
	echo "== config test FAILED =="
	echo "$DATA"
	echo "========================"
fi

true
