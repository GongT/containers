#!/usr/bin/env bash

set -Eeuo pipefail

### 通过安装系统自带的nginx，运行nginx -V看原本的编译参数
CC_OPT='-O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -Wno-error'
LD_OPT='-Wl,-z,defs -Wl,-z,now -Wl,-z,relro -Wl,-E'

cd "/opt/source/nginx"

# export LUAJIT_LIB=/usr/lib64
# export LUAJIT_INC=/usr/include/luajit-2.1

MODULES=()
for REL_FOLDER in ../modules/*/
do
	MODULES+=("--add-module=$REL_FOLDER")
done

./auto/configure \
	"${MODULES[@]}" \
	'--prefix=/usr/' \
	'--sbin-path=/usr/sbin' \
	'--modules-path=/usr/nginx/modules' \
	'--conf-path=/etc/nginx/nginx.conf' \
	'--error-log-path=/var/log/error.log' \
	'--http-log-path=/var/log/access.log' \
	'--http-client-body-temp-path=/tmp/client_body' \
	'--http-proxy-temp-path=/tmp/proxy' \
	'--http-fastcgi-temp-path=/tmp/fastcgi' \
	'--http-uwsgi-temp-path=/tmp/uwsgi' \
	'--http-scgi-temp-path=/tmp/scgi' \
	'--pid-path=/run/nginx.pid' \
	'--lock-path=/run/lock/subsys/nginx' \
	'--user=nginx' \
	'--group=nginx' \
	'--with-compat' \
	'--without-select_module' \
	'--without-poll_module' \
	'--with-threads' \
	'--with-file-aio' \
	'--with-http_ssl_module' \
	'--with-http_v2_module' \
	'--with-http_realip_module' \
	'--with-http_addition_module' \
	'--with-http_xslt_module' \
	'--with-http_xslt_module' \
	'--with-http_image_filter_module' \
	'--with-http_geoip_module' \
	'--with-http_sub_module' \
	'--with-http_dav_module' \
	'--with-http_flv_module' \
	'--with-http_mp4_module' \
	'--with-http_gunzip_module' \
	'--with-http_gzip_static_module' \
	'--with-http_auth_request_module' \
	'--with-http_random_index_module' \
	'--with-http_secure_link_module' \
	'--with-http_degradation_module' \
	'--with-http_slice_module' \
	'--with-http_stub_status_module' \
	'--with-stream' \
	'--with-stream_ssl_module' \
	'--with-stream_realip_module' \
	'--with-stream_geoip_module' \
	'--with-stream_ssl_preread_module' \
	'--with-google_perftools_module' \
	'--with-pcre' \
	'--with-pcre-jit' \
	'--with-libatomic' \
	'--with-debug' \
	"--with-cc-opt=$CC_OPT" \
	"--with-ld-opt=$LD_OPT"

make BUILDTYPE=Debug -j

DST=/opt/dist
rm -rf $DST
mkdir -p $DST/usr/sbin

make DESTDIR=$DST install

rm -rf $DST/etc
mkdir -p $DST/etc/nginx

#######
function copy_binary() {
	echo "copy binary $1"
	for i in $(ldd "$1" | grep '=>' | awk '{print $3}') ; do
		if [[ "$i" == not ]]; then
			echo 'Failed to resolve some dependencies of nginx.' >&2 ; exit 1
		fi

		mkdir -p "$(dirname "$DST/$i")"
		cp -u "$i" "$DST/$i"
	done

	for i in $(ldd "$1" | grep -v '=>' | awk '{print $1}') ; do
		if [[ "$i" =~ linux-vdso* ]]; then
			continue
		fi
		mkdir -p "$(dirname "$DST/$i")"
		cp -u "$i" "$DST/$i"
	done
}

copy_binary /opt/dist/usr/sbin/nginx
copy_binary /usr/bin/htpasswd
copy_binary /bin/bash
copy_binary /bin/mkdir

for i in /lib64/libnss_{compat*,dns*,files*,myhostname*,resolve*} ; do
	cp -uv "$i" "$DST/$i"
done

mkdir -p "$DST/usr/bin"
cp /bin/bash /bin/mkdir /bin/rm /usr/bin/htpasswd "$DST/usr/bin"

mkdir -p "$DST/etc"
echo "nameserver 8.8.8.8
nameserver 1.1.1.1
" > "$DST/etc/resolv.conf"

echo "create openssl cert..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -batch \
	-keyout "$DST/etc/nginx/selfsigned.key" \
	-out "$DST/etc/nginx/selfsigned.crt"

cp /etc/passwd /etc/group /etc/nsswitch.conf "$DST/etc"

echo "Done."
