#!/bin/bash

export SYSTEMD_RELOAD=no
for i in */install-service.sh ; do
	bash "$i"
done
systemctl daemon-reload

