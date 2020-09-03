#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

function usage() {
	local Z=$0
	echo "Usage: $Z action
Actions:"
	l() {
		local N=$1
		shift
		echo -e "    \e[38;5;14m$N\e[0m: $*"
	}
	if [[ "$Z" = */bin.sh ]]; then
		l install "install (link) bin.sh to /usr/local/bin/ms, and create auto-pull timer"
	fi
	l status "show status of all services"
	l upgrade "update (re-install) services files"
	l ls "list all service names"
	l start "start all"
	l restart "restart all"
	l stop "reload all"
	l stop "stop all"
	l logs "show all logs (-f for watch mode)"
	l pause "prevent startup, if it (re-)starting"
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
ls)
	do_ls
	;;
start | restart | stop | reload)
	do_ls | xargs --no-run-if-empty -t systemctl "$ACTION"
	;;
logs)
	LARGS=()
	for i in $(do_ls); do
		LARGS+=("-u" "$i")
	done
	journalctl "${LARGS[@]}" "$@"
	;;
pause)
	systemctl list-units '*.pod@.service' '*.pod.service' --all --no-pager --no-legend | grep activating \
		| awk '{print $1}' | xargs --no-run-if-empty -t
	;;
*)
	usage
	die "unknown action: $ACTION"
	;;
esac
