dnf_install_step "systemd-graphical" scripts/dependencies.lst
merge_local_fs "systemd-graphical" scripts/prepare.sh
setup_systemd "systemd-graphical" \
	basic "DEFAULT_TARGET=graphical.target" \
	enable "REQUIRE=novnc.service i3.service" \
	socket_proxy "PORTS=novnc:6080/tcp vnc:5900/tcp"
