echo '[global]' >/etc/pip.conf
echo 'cache-dir=/var/cache/pip' >>/etc/pip.conf
echo 'index-url=https://pypi.tuna.tsinghua.edu.cn/simple' >>/etc/pip.conf
python3 -m venv /hass/python
dnf.sh erase -y python3-pip
/hass/python/bin/python -m pip install --upgrade pip
