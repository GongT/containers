#!/usr/bin/env bash

set -Eeuo pipefail

cd /backup/automatic

STATUS_FILE="/backup/automatic/status.conf"
if [[ -e $STATUS_FILE ]]; then
	source "$STATUS_FILE"
fi

ROOT_FOLDER="/backup/automatic/$(date "+%+4Y-%m")"
DAY_NUM=$(date "+%d")
TARGET_FOLDER="$ROOT_FOLDER/$DAY_NUM"

if [[ -e $TARGET_FOLDER ]]; then
	echo "本日备份已经存在: $TARGET_FOLDER"
	exit 0
fi

if [[ -d ${CURRENT:-} ]] && [[ ${INCREMENT_NUMBER:=0} -le 7 ]]; then
	echo "本日增量备份 [增量数${INCREMENT_NUMBER}]: $TARGET_FOLDER | 基础: $CURRENT"
	mariabackup --backup --defaults-group=mysql --user=root "--target-dir=$TARGET_FOLDER" "--incremental-basedir=$CURRENT"
	INCREMENT_NUMBER=$((INCREMENT_NUMBER + 1))
else
	echo "全量备份: $TARGET_FOLDER"
	mariabackup --backup --defaults-group=mysql --user=root "--target-dir=$TARGET_FOLDER"
	INCREMENT_NUMBER=1
fi

{
	printf "INCREMENT_NUMBER=%q\n" "$INCREMENT_NUMBER"
	printf "CURRENT=%q\n" "$TARGET_FOLDER"
} | tee "$STATUS_FILE"
