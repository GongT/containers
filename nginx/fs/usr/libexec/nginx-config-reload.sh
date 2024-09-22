#!/usr/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/xbin

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
