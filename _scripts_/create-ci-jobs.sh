#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..

TABLE="| Container | Link | Build Status |
|----:|:----|:----:|
"
for i in */build.sh; do
	PROJ=$(basename "$(dirname "$i")")
	F=".github/workflows/generated-build-$PROJ.yaml"

	sed "s#{{PROJ}}#$PROJ#g" _scripts_/template.yaml > "$F"

	TABLE+="| $PROJ " 
	TABLE+="| https://hub.docker.com/r/gongt/$PROJ " 
	TABLE+="| [![$PROJ](https://github.com/GongT/containers/workflows/$PROJ/badge.svg)](https://github.com/GongT/containers/actions?query=workflow%3A$PROJ)"
	TABLE+=" |" 
	TABLE+=$'\n'
done

DATA=$(sed -n "/StatusTable:/{p; :a; N; /:StatusTable/!ba; s/.*\n/__TABLE_BODY__/}; p" README.md)
DATA="${DATA/__TABLE_BODY__/"$TABLE"}"

echo "$DATA" > README.md
