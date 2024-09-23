#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

source "../common/package/include.sh"

PARGS=()
HTARGS=()
HTOPT=''
TTY=yes

usage() {
	if [[ $# -gt 0 ]]; then
		printf 'htpasswd: %s\n' "$*" >&2
	fi
	printf 'Usage:
	htpasswd [-iDv] [-C cost] username
  -i  Read password from stdin without verification (for script usage).
  -D  Delete the specified user.
  -v  Verify password for the specified user.
  -C  Set the computing time used for the bcrypt algorithm
      (higher is more secure but slower, default: 5, valid: 4 to 17).
' >&2

	if [[ $# -eq 0 ]]; then
		exit 0
	else
		exit 1
	fi
}

while getopts hiC:Dv VAR_ARG; do
	case "${VAR_ARG}" in
	i)
		if is_tty 0; then
			die "-i set but standard input is tty."
		fi

		TTY=no
		HTOPT+='i'
		;;
	C)
		if [[ $OPTARG -lt 4 || $OPTARG -gt 17 ]]; then
			usage "invalid cost: $OPTARG"
		fi
		HTARGS+=("-C" "$OPTARG")
		;;
	D)
		TTY=no
		HTOPT+='D'
		;;
	v)
		HTOPT+='v'
		;;
	h)
		usage
		;;
	*)
		usage "invalid arg: $VAR_ARG"
		;;
	esac
done
shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
	usage "missing username"
elif [[ $# -gt 1 ]]; then
	usage "invalid argument: $2"
fi
USER=$1

if [[ -n ${HTOPT} ]]; then
	HTARGS=("-${HTOPT}" "${HTARGS[@]}")
fi

if ! is_tty 0; then
	TTY=no
fi

CID="$(get_container_id)"
set -x
exec podman exec "${PARGS[@]}" \
	--workdir=/config \
	-it \
	"${CID}" \
	/usr/bin/htpasswd "${HTARGS[@]}" htpasswd "$USER"
