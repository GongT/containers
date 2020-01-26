source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/functions.sh"

function create_if_not() {
    buildah inspect --type container --format '{{.Container}}' "$1" || buildah from --name "$1" "$2"
}

function new_container() {
	local NAME=$1
	local EXISTS=$(buildah inspect --type container --format '{{.Container}}' "$NAME" || true)
	if [[ -n "$EXISTS" ]]; then
		buildah rm "$EXISTS"
	fi
	buildah from --name "$NAME" "${2-scratch}"
}
