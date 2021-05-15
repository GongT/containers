#!/usr/bin/env bash

function x() {
	echo -e "\e[48;5;10;38;5;0m$*\e[0m" >&2
	"$@"
}

export GO111MODULE="auto"
export GOCACHE="$SYSTEM_COMMON_CACHE/golang"
export GOMODCACHE="$SYSTEM_COMMON_CACHE/golang.mod"
export GOPATH=/go
export GOPROXY="https://proxy.golang.org"
export PATH="$GOPATH/bin:$PATH"

x go build -o "$ARTIFACT_PREFIX/bin/x-www-browser" cmd/client.go
x chmod a+x "$ARTIFACT_PREFIX/bin/x-www-browser"

echo "broadcaster built complete!"
ls -l "$ARTIFACT_PREFIX/bin/x-www-browser"
