#!/usr/bin/bash

ROOT=$1

echo "start sync at folder $ROOT" >&2

cd "${ROOT}"

git push
RET=$?

echo "git push return $RET" >&2
exit $RET
