export GOPATH=/go
export PATH="$GOPATH/bin:$PATH"

if ! command -v dep &>/dev/null; then
	mkdir -p "/go/bin"
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
fi
