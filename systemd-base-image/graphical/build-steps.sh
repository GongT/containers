dnf_install_step base_graphical scripts/dependencies.lst
merge_local_fs base_graphical scripts/prepare.sh
setup_systemd base_graphical \
	basic "DEFAULT_TARGET=graphical.target" \
	enable "REQUIRE=novnc.service i3.service" \
	socket_proxy "PORTS=novnc:6080/tcp vnc:5900/tcp"
