#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../../common/functions-build.sh

RESULT=$(create_if_not test alpine)
MNT=$(buildah mount $RESULT)

cat << 'EOF' > "$MNT/test.sh"
echo "Start!!!!"
echo "============================================"
env
echo "============================================"

I=0
while true ; do
	I=$(($I + 1))
	if [[ "${ACTIVE_FILE+def}" = "def" ]] && [[ "$I" -gt 3 ]]; then
		echo "touch $ACTIVE_FILE"
		touch "$ACTIVE_FILE"
	fi
	date "$(echo -e "+$I:\t %F %T")"
	sleep 1
done
exit 0
EOF

buildah config --cmd '/bin/sh /test.sh' "$RESULT"
buildah commit "$RESULT" gongt/test
info "done."
