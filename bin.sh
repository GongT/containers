#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

function usage() {
	local Z=$0
	echo "Usage: $Z action"
	echo
	echo "Containers Management:"
	l() {
		local N=$1
		shift
		echo -e "    \e[38;5;14m$N\e[0m: $*"
	}
	if [[ "$Z" = */bin.sh ]]; then
		l install "install (link) bin.sh to /usr/local/bin/ms, and create auto-pull timer"
	fi
	l upgrade "update (re-install) services files"

	echo
	echo "Service Control:"
	l status "show status of all services"
	l ls "list all service names"
	for I in start restart stop reload reset-failed; do
		l "$I" "$I all service at once"
	done
	l logs "show all logs (-f for watch mode)"
	l abort "prevent startup, if it (re-)starting"

	echo
	echo "Tools:"
	l run "run command in container (default /bin/sh)"
	l rm "remove (uninstall) service file"
	echo
}

if [[ $# -eq 0 ]]; then
	usage >&2
	exit 0
fi

go_home() {
	cd "$(dirname "$(readlink "$0")")" || die "failed chdir to containers source folder"
	if ! [[ -e "bin.sh" ]]; then
		die "failed chdir to containers source folder (wd: $(pwd))"
	fi
}

do_rm() {
	go_home
	local T=$1 FILES I
	mapfile -t FILES < <(systemctl list-unit-files "$T.pod@.service" "$T.pod.service" "$T.service" --all --no-pager --no-legend | awk '{print $1}')

	for I in "${FILES[@]}"; do
		local OVERWRITE="/etc/systemd/system/$I.d"
		if [[ -d "$OVERWRITE" ]]; then
			echo "remove directory: $OVERWRITE"
			rm -rf "$OVERWRITE"
		fi

		echo -ne "disable (and stop) service $I\n    "
		systemctl disable --now --no-block "$I" || true

		local F="/usr/lib/systemd/system/$I"
		if [[ -e "$F" ]]; then
			echo "remove service file: $F"
			rm -f "$F"
		fi
	done

	if [[ "${#FILES[@]}" -gt 0 ]]; then
		systemctl daemon-reload
	fi
}

do_ls() {
	systemctl list-unit-files '*.pod@.service' '*.pod.service' --all --no-pager --no-legend | awk '{print $1}' | sed -E 's/\.service$//g'
}

declare -r ACTION=$1
shift

if [[ "$ACTION" == install ]] && ! [[ -L "$0" ]]; then
	go_home

	mkdir -p /usr/share/scripts
	cp _scripts_/podman-auto-pull.service _scripts_/podman-auto-pull.timer -t /usr/lib/systemd/system/
	cp _scripts_/podman-auto-pull.sh /usr/share/scripts/podman-auto-pull.sh

	systemctl daemon-reload
	systemctl enable --now podman-auto-pull.timer

	if [[ -e "/usr/local/bin/ms" ]] || [[ -L "/usr/local/bin/ms" ]]; then
		rm -f /usr/local/bin/ms
	fi
	ln -vs "$(realpath "$0")" /usr/local/bin/ms
	exit
fi

case "$ACTION" in
status)
	systemctl list-units '*.pod@.service' '*.pod.service' --all --no-pager
	;;
upgrade)
	go_home
	bash ./upgrade.sh
	;;
rm)
	if ! [[ "${1:-}" ]]; then
		usage >&2
		die "missing 1 argument"
	fi
	do_rm "$1"
	;;
ls)
	do_ls
	;;
start | restart | stop | reload | reset-failed)
	do_ls | xargs --no-run-if-empty -t systemctl "$ACTION"
	;;
logs)
	LARGS=()
	for i in $(do_ls); do
		LARGS+=("-u" "$i")
	done
	journalctl "${LARGS[@]}" "$@"
	;;
abort)
	systemctl list-units '*.pod@.service' '*.pod.service' --all --no-pager --no-legend | grep activating \
		| awk '{print $1}' | xargs --no-run-if-empty -t systemctl stop
	;;
run)
	TARGET="$1"
	shift
	if [[ $# -gt 0 ]]; then
		CMD="$1"
		shift
	else
		CMD="sh"
	fi

	if systemctl list-units '*.pod@.service' '*.pod.service' --no-pager --no-legend | grep running | awk '{print $1}' | grep -q "$TARGET"; then
		set -x
		exec podman exec -it "$TARGET" "$CMD" "$@"
	else
		die "target service ($TARGET) is not running"
	fi
	;;
*)
	usage
	die "unknown action: $ACTION"
	;;
esac
