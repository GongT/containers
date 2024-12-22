STEP="安装图形界面"
dnf_install_step "systemd-graphical" scripts/dependencies.lst
STEP="复制图形界面配置文件"
merge_local_fs "systemd-graphical" scripts/prepare.sh
STEP="配置vnc服务"
setup_systemd "systemd-graphical" \
	basic "DEFAULT_TARGET=graphical.target" \
	enable "REQUIRE=novnc.service i3.service" \
	socket_proxy "PORTS=novnc:6080/tcp vnc:5900/tcp"
