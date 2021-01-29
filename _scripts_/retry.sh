#!/usr/bin/env bash

{
	echo "============================== Environment =============================="
	env
	echo "============================== Action =============================="
	echo "$*"
	echo "===================================================================="
} >&2

for I in $(seq 1 3); do
	echo "============================== try $I ==============================" >&2
	"$@"
	RET=$?
	echo "============================== try $I exit $RET ====================" >&2
	if [[ $RET -eq 0 ]]; then
		exit 0
	fi
done

echo "::: Failed with proxy, retry without proxy :::" >&2

export http_proxy='' https_proxy='' all_proxy='' HTTP_PROXY='' HTTPS_PROXY='' ALL_PROXY=''
for I in $(seq 1 3); do
	echo "============================== try $I ==============================" >&2
	"$@"
	RET=$?
	echo "============================== try $I exit $RET ====================" >&2
	if [[ $RET -eq 0 ]]; then
		exit 0
	fi
done

exit $RET
