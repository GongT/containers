#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

RESULT=$(create_if_not certbot-result alpine)
info "base image prepare..."

buildah copy "$RESULT" opt /opt
info "files created..."

echo '
set -e
apk add -U ca-certificates bash curl wget openssl

cd /opt/acme.sh
bash acme.sh --install \
	--home /usr/bin \
	--config-home "/etc/letsencrypt/acme.sh" \
	--accountemail "admin@example.com" \
	--accountkey /etc/letsencrypt/acme.sh/account.key \
	--accountconf /etc/letsencrypt/acme.sh/account.conf \
	--nocron \
	--noprofile

echo "
# min   hour    day     month   weekday command
0       0       */20    *       *       run-parts /etc/periodic/20day
" > /etc/crontabs/root

mkdir -p /etc/periodic/20day

' | buildah run $(use_alpine_apk_cache) "$RESULT" sh
info "install complete..."

buildah config --entrypoint '["/bin/bash"]' --cmd '/opt/init.sh' --stop-signal=SIGINT "$RESULT"
buildah config --volume /config --volume /etc/letsencrypt "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/certbot-dns "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/certbot-dns
info "Done!"
