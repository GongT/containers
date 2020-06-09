#!/bin/bash

export SYSTEMD_RELOAD=no
for i in */install-service.sh; do
	T=$(mktemp)
	echo -n "$i: "
	if bash "$i" &> "$T"; then
		echo -e "\e[38;5;10mOK!\e[0m"
	else
		echo -e "\e[38;5;9mFail!\e[0m"
	fi
done
systemctl daemon-reload

systemctl list-unit-files '*.pod@.service' '*.pod.service' --all --no-pager
