#!/usr/bin/env bash

set -Eeuo pipefail

cd "$SOURCE/luajit2"
group "=== install '$(basename "$(pwd)")'..."
export LUAJIT_LIB=/usr/lib64
export LUAJIT_INC=/usr/include/luajit-2.1
make clean
make MULTILIB=lib64 PREFIX=/usr -j
make MULTILIB=lib64 PREFIX=/usr "INSTALL_INC=$LUAJIT_INC" "INSTALL_JITLIB=$ARTIFACT_PREFIX/usr/share/lua/5.1" install
groupEnd

ln -s luajit /usr/bin/lua # for following build steps

mapfile -t LIB_PS < <(find "$SOURCE/resty/" -maxdepth 1 -mindepth 1 -type d)
for LIB_P in "${LIB_PS[@]}"; do
	cd "$LIB_P"
	group "=== install '$(basename "$(pwd)")'..."
	make "DESTDIR=$ARTIFACT_PREFIX" LUA_LIB_DIR=/usr/share/lua/5.1 PREFIX=/usr
	make "DESTDIR=$ARTIFACT_PREFIX" LUA_LIB_DIR=/usr/share/lua/5.1 PREFIX=/usr install
	groupEnd
done

### fix path wrong
mkdir -p "$ARTIFACT_PREFIX/usr/local/lib/lua/5.1"
mapfile -t LIBFILES < <(find "$ARTIFACT_PREFIX/usr/share/lua/5.1/" -name '*.so')
for FILE_PATH in "${LIBFILES[@]}"; do
	x mv "$FILE_PATH" "$ARTIFACT_PREFIX/usr/local/lib/lua/5.1/$(basename "$FILE_PATH")"
done

### END of resty libs

cd "$SOURCE/lua/luaposix"
group "=== install '$(basename "$(pwd)")'..."
# LUA_LIBDIR
./build-aux/luke "LUA_INCDIR=$LUAJIT_INC" "PREFIX=$ARTIFACT_PREFIX/usr/local" LUAVERSION=5.1
./build-aux/luke "LUA_INCDIR=$LUAJIT_INC" "PREFIX=$ARTIFACT_PREFIX/usr/local" LUAVERSION=5.1 install
groupEnd

cd "$SOURCE/nginx"

export CC_OPT='-O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -Wno-error'
export LD_OPT='-Wl,-z,defs -Wl,-z,now -Wl,-z,relro -Wl,-E'

MODULES=()
for REL_FOLDER in ../modules/*/; do
	MODULES+=("--add-module=$REL_FOLDER")
done

OTHER_MODULES=()
OTHER_MODULES+=("--add-module=../special-modules/njs/nginx")

group "=== configure nginx"
### TODO: 通过安装系统自带的nginx，运行nginx -V看原本的编译参数
./auto/configure \
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
	"--with-ld-opt=$LD_OPT" \
	"${MODULES[@]}" \
	"${OTHER_MODULES[@]}"
groupEnd

group "=== build nginx"
make BUILDTYPE=Debug -j
groupEnd

group "=== install nginx"
mkdir -p "$ARTIFACT_PREFIX/usr/sbin"

make "DESTDIR=$ARTIFACT_PREFIX" install

rm -rf "$ARTIFACT_PREFIX/etc"
groupEnd
