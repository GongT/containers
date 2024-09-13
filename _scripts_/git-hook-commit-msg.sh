#!/usr/bin/env bash
COMMIT_MSG=$(< "$1")

if [[ $COMMIT_MSG != '['*']'* ]] ; then
	echo "提交内容($COMMIT_MSG)不符合规则（缺少项目名称）" >&2
	exit 1
fi
