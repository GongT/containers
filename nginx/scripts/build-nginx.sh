#!/usr/bin/env bash

set -Eeuo pipefail

# cd "$SOURCE/luajit2"
# info "=== install '$(pwd)'..."
# indent
# export LUAJIT_LIB=/usr/lib64
# export LUAJIT_INC=/usr/include/luajit-2.1
# indent_stream make clean
# indent_stream make MULTILIB=lib64 PREFIX=/usr -j
# indent_stream make MULTILIB=lib64 PREFIX=/usr "INSTALL_INC=$LUAJIT_INC" "INSTALL_JITLIB=$ARTIFACT_PREFIX/usr/share/lua/5.1" install
# dedent

# ## BEGIN of resty libs
# rm -f /usr/bin/lua
# ln -s luajit /usr/bin/lua # for following build steps

# find "$SOURCE/resty/" -maxdepth 1 -mindepth 1 -type d | while read -r LIB_P; do
# 	cd "$LIB_P"
# 	info "=== install '$(pwd)'..."
# 	indent_stream make "DESTDIR=$ARTIFACT_PREFIX" LUA_LIB_DIR=/usr/share/lua/5.1 "LUA_INCLUDE_DIR=${SOURCE}/luajit2/src" PREFIX=/usr
# 	indent_stream make "DESTDIR=$ARTIFACT_PREFIX" LUA_LIB_DIR=/usr/share/lua/5.1 "LUA_INCLUDE_DIR=${SOURCE}/luajit2/src" PREFIX=/usr install
# 	dedent
# done

# ### fix path wrong
# mkdir -p "$ARTIFACT_PREFIX/usr/local/lib/lua/5.1"
# find "$ARTIFACT_PREFIX/usr/share/lua/5.1/" -name '*.so' | while read -r FILE_PATH; do
# 	x mv "$FILE_PATH" "$ARTIFACT_PREFIX/usr/local/lib/lua/5.1/$(basename "$FILE_PATH")"
# done

# ### END of resty libs

# cd "$SOURCE/lua/luaposix"
# info "=== install '$(pwd)'..."
# indent
# # LUA_LIBDIR
# ./build-aux/luke "LUA_INCDIR=$LUAJIT_INC" "PREFIX=$ARTIFACT_PREFIX/usr/local" LUAVERSION=5.1
# ./build-aux/luke "LUA_INCDIR=$LUAJIT_INC" "PREFIX=$ARTIFACT_PREFIX/usr/local" LUAVERSION=5.1 install
# dedent

cd "$SOURCE/nginx"

export CC_OPT='-O2 -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Wno-complain-wrong-lang -Werror=format-security -Wp,-U_FORTIFY_SOURCE,-D_FORTIFY_SOURCE=3 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -march=x86-64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -mtls-dialect=gnu2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer'
export LD_OPT='-Wl,-z,relro -Wl,--as-needed -Wl,-z,pack-relative-relocs -Wl,-z,now -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -specs=/usr/lib/rpm/redhat/redhat-hardened-ld-errors -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -Wl,--build-id=sha1'

MODULES=()
for REL_FOLDER in ../modules/*/; do
	MODULES+=("--add-module=$REL_FOLDER")
done

OTHER_MODULES=()
OTHER_MODULES+=("--add-module=../special-modules/njs/nginx")

{
	echo '------------------------------------'
	./auto/configure --help || true
	echo '------------------------------------'
} >&2

info "=== configure nginx"
indent
### TODO: 通过安装系统自带的nginx，运行nginx -V看原本的编译参数
indent_stream ./auto/configure \
	'--prefix=/usr/' \
	'--sbin-path=/usr/bin' \
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
	'--with-compat' \
	'--without-select_module' \
	'--without-poll_module' \
	'--with-threads' \
	'--with-file-aio' \
	'--with-http_ssl_module' \
	'--with-http_v2_module' \
	'--with-http_v3_module' \
	'--with-http_realip_module' \
	'--with-http_addition_module' \
	'--with-http_xslt_module' \
	'--with-http_xslt_module' \
	'--with-http_image_filter_module' \
	'--with-http_geoip_module' \
	'--with-http_sub_module' \
	'--with-http_dav_module' \
	'--with-http_mp4_module' \
	'--with-http_gunzip_module' \
	'--with-http_gzip_static_module' \
	'--with-http_auth_request_module' \
	'--with-http_random_index_module' \
	'--with-http_secure_link_module' \
	'--with-http_degradation_module' \
	'--with-http_slice_module' \
	'--with-http_json_module' \
	'--with-http_stub_status_module' \
	'--with-stream' \
	'--with-stream_ssl_module' \
	'--with-stream_realip_module' \
	'--with-stream_geoip_module' \
	'--with-stream_ssl_preread_module' \
	'--with-google_perftools_module' \
	'--with-libatomic' \
	'--with-debug' \
	"--with-cc-opt=$CC_OPT" \
	"--with-ld-opt=$LD_OPT" \
	"${MODULES[@]}" \
	"${OTHER_MODULES[@]}"
dedent

info "=== build nginx"
indent
indent_stream make BUILDTYPE=Debug -j
dedent

info "=== install nginx"
indent
mkdir -p "$ARTIFACT_PREFIX/usr/bin"

indent_stream make "DESTDIR=$ARTIFACT_PREFIX" install

"$ARTIFACT_PREFIX/usr/bin/nginx" -V

rm -rf "$ARTIFACT_PREFIX/etc"
dedent
