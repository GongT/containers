echo 'LANG=zh_CN.UTF-8
LC_TIME=en_DK.UTF-8
LC_MEASUREMENT=metric
' >/etc/locale.conf

/usr/bin/busybox.shared --install

systemctl disable systemd-logind.service systemd-sysusers.service getty.target
systemctl disable systemd-resolved-monitor.socket systemd-resolved-varlink.socket

# 自带的networkd和resolved服务定义要求一些容器中不存在的权限，直接屏蔽它们，需要的时候手动创建unit
systemctl mask systemd-networkd.service systemd-resolved.service

# 配置 systemd-logind 依赖于 dbus.socket
mkdir -p /usr/lib/systemd/system/systemd-logind.service.d
echo "[Unit]
Requires=dbus.socket
After=dbus.socket

[Install]
WantedBy=
WantedBy=graphical.target
" >/usr/lib/systemd/system/systemd-logind.service.d/00-requires-dbus.conf
