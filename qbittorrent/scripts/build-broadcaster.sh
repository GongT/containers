#!/usr/bin/env bash

set -e

export GOPATH=/go
export PATH="$GOPATH/bin:$PATH"

mkdir -p "$GOPATH/src"
cd "$GOPATH/src"
rm -f proj
ln -s "$SOURCE" proj
cd proj

set -x
dep ensure -update
go build -o "$ARTIFACT/x-www-browser" cmd/client.go
chmod a+x "$ARTIFACT/x-www-browser"
