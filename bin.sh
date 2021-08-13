#!/usr/bin/env bash

set -Eeuo pipefail

CONTROL_SERVICES=(wait-all-fstab.service create-dnsmasq-config.service wait-dns-working.service containers-ensure-health.timer)

function die() {
	echo "$*" >&2
	exit 1
}

function usage() {
	local Z=$0
	echo "用法: $Z action"
	echo
	echo "镜像管理:"
	l() {
		local N=$1
		shift
		echo -e "    \e[38;5;14m$N\e[0m: $*"
	}
	if [[ $Z == */bin.sh ]]; then
		l install "安装（链接）bin.sh 到 /usr/local/bin/ms，并安装自动拉镜像的脚本"
	fi
	l upgrade "重新执行所有已安装服务的安装脚本"

	echo
	echo "服务控制:"
	l status "显示所有服务状态"
	l ls "（用于脚本）列出服务名称"
	for I in start restart stop reload reset-failed; do
		l "$I" "对每个服务使用${I}命令"
	done
	l log "显示单个服务本次运行的日志（-f：跟踪模式）"
	l logs "显示服务日志（-f：跟踪模式）"
	l abort "如果服务正在启动，则中止启动过程"
	l refresh "检查哪些容器的镜像已经更新（--run：自动运行重启命令）"

	echo
	echo "其他工具:"
	l run "在镜像里运行命令（默认运行sh）"
	l rm "停止服务，并删除服务文件"
	l pull "拉取新镜像版本（--force：无视最近记录）"
	echo
}

if [[ $# -eq 0 ]]; then
	systemctl list-units --no-legend --all --no-pager --type=service '*.pod@*.service' '*.pod.service' "${CONTROL_SERVICES[@]}"
	systemctl list-unit-files --no-legend --no-pager --state=disabled --type=service '*.pod.service' "${CONTROL_SERVICES[@]}"
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
	mapfile -t FILES < <(systemctl list-unit-files "$T.pod@.service" "$T.pod.service" --all --no-pager --no-legend | awk '{print $1}')

	for I in "${FILES[@]}"; do
		local OVERWRITE="/etc/systemd/system/$I.d"
		if [[ -d $OVERWRITE ]]; then
			echo "remove directory: $OVERWRITE"
			rm -rf "$OVERWRITE"
		fi

		echo -ne "disable (and stop) service $I\n    "
		systemctl disable --now --no-block "$I" || true

		local F="/usr/lib/systemd/system/$I"
		if [[ -e $F ]]; then
			echo "remove service file: $F"
			rm -f "$F"
		fi
	done

	if [[ ${#FILES[@]} -gt 0 ]]; then
		systemctl daemon-reload
	fi
}

do_ls() {
	{
		systemctl list-units --all --no-pager --no-legend --type=service '*.pod@*.service' '*.pod.service' | sed 's/●//g' | awk '{print $1}'
		systemctl list-unit-files --no-legend --no-pager --state=disabled --type=service '*.pod.service' | awk '{print $1}'
	} | sed -E 's/\.service$//g' | sort
}

do_refresh() {
	local NEED_RESTART=() I
	local -A CONTAINER_SERVICE_MAP=()
	for I in $(do_ls); do
		CONTAINER_SERVICE_MAP["$(echo "$I" | sed -E 's/\.pod$//g; s/\.pod@/_/g')"]="$I"
	done

	while read -r CONTAINER IMAGE_ID IMAGE_NAME; do
		WANT_ID=$(podman inspect "$IMAGE_NAME" --type=image --format='{{.Id}}')
		if ! [[ $WANT_ID ]]; then
			echo "$IMAGE_NAME not exists" >&2
			continue
		fi
		if [[ $WANT_ID == "$IMAGE_ID" ]]; then
			UP_TO_DATE+=("${CONTAINER_SERVICE_MAP[$CONTAINER]}")
		else
			NEED_RESTART+=("${CONTAINER_SERVICE_MAP[$CONTAINER]}")
		fi
	done < <(podman inspect "${!CONTAINER_SERVICE_MAP[@]}" --type=container --format='{{.Name}} {{.Image}} {{.ImageName}}' || true)

	echo "${UP_TO_DATE[*]} is up to date" >&2
	echo "need update: ${NEED_RESTART[*]}"
	if [[ $* == *--run* ]]; then
		systemctl restart "${NEED_RESTART[@]}"
	fi
}

pull_all() {
	echo "$*"
	local ARG IMAGES=()
	for ARG in "${@}"; do
		if [[ $ARG == '--force' ]]; then
			export FORCE_PULL=yes
		else
			IMAGES+=("${ARG}")
		fi
	done
	set -- "${IMAGES[@]}"
	go_home
	source _scripts_/pull_all_images.sh "$@"
}

declare -r ACTION=$1
shift

if [[ $ACTION == install ]] && ! [[ -L $0 ]]; then
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
upgrade)
	go_home
	bash ./upgrade.sh
	;;
refresh)
	do_refresh "$@"
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
start | restart | stop | reload | reset-failed | status | enable | disable)
	do_ls | xargs --no-run-if-empty -t systemctl "$ACTION"
	;;
log)
	IARGS=() NARGS=()
	for I; do
		if [[ $I == -f ]]; then
			NARGS+=(-f)
		else
			IARGS+=("$I")
		fi
	done

	if [[ ${#IARGS[@]} -ne 1 ]]; then
		die "must 1 argument"
	fi
	V=${IARGS[0]}
	if [[ $V != *.pod ]]; then
		V+=".pod"
	fi
	IID=$(systemctl show -p InvocationID --value "$V.service")
	echo "InvocationID=$IID"
	journalctl "${NARGS[@]}" "_SYSTEMD_INVOCATION_ID=$IID"
	;;
logs)
	LARGS=() NARGS=()
	for I; do
		if [[ $I == -f ]]; then
			NARGS+=(-f)
		else
			LARGS+=(-u "$I")
		fi
	done
	if [[ ${#LARGS[@]} -eq 0 ]]; then
		for i in $(do_ls); do
			LARGS+=("-u" "$i")
		done
	fi
	journalctl "${LARGS[@]}" "${NARGS[@]}"
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
pull)
	pull_all "$@"
	;;
*)
	usage
	die "unknown action: $ACTION"
	;;
esac
