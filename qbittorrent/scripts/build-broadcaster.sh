#!/usr/bin/env bash

set -e

cd /data/DevelopmentRoot/GoLang/src/github.com/gongt/remote-shell
export GOPATH=/data/DevelopmentRoot/GoLang
export PATH="$GOPATH/bin:$PATH"

if ! command -v dep &>/dev/null ; then
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
fi

dep ensure -update
go build -o "$ARTIFACT/x-www-browser" cmd/client.go
chmod a+x "$ARTIFACT/x-www-browser"
