groupadd -g "10100" "vnc"
useradd --gid "10100" --no-create-home --no-user-group --uid "10100" "vnc"
systemctl disable xvnc.socket
