#!/usr/bin/env bash

set -Eeuo pipefail

export PROJECT_NAME=''

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..

mapfile -d '' -t BUILD_FILES < <(find . -maxdepth 2 -name build.sh -print0 | sort --zero-terminated --dictionary-order)

TABLE="| Container | Link | Build Status |
|----:|:----|:----:|
"
for i in "${BUILD_FILES[@]}"; do
	if [[ -e $(realpath -m "$i/../disabled") ]]; then
		continue
	fi
	export PROJECT_NAME=$(basename "$(dirname "$i")")

	TABLE+="| $PROJECT_NAME "
	TABLE+="| https://github.com/GongT/containers/pkgs/container/$PROJECT_NAME "
	TABLE+="| [![$PROJECT_NAME](https://github.com/GongT/containers/workflows/$PROJECT_NAME/badge.svg)](https://github.com/GongT/containers/actions?query=workflow%3A$PROJECT_NAME)"
	TABLE+=" |"
	TABLE+=$'\n'
done

DATA=$(sed -n "/StatusTable:/{p; :a; N; /:StatusTable/!ba; s/.*\n/__TABLE_BODY__/}; p" README.md)
DATA="${DATA/__TABLE_BODY__/"$TABLE"}"

echo "$DATA" >README.md
