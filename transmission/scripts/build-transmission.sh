#!/usr/bin/env bash

function x() {
	echo -e "\e[48;5;10;38;5;0m$*\e[0m" >&2
	"$@"
}

DEFINES=()
function D() {
	name=$1
	value=$2

	DEFINES+=("-D$name=$value")
}

D ENABLE_DAEMON ON        # "Build daemon" ON
D ENABLE_GTK OFF          # "Build GTK+ client" AUTO
D ENABLE_QT OFF           # "Build Qt client" AUTO
D ENABLE_MAC OFF          # "Build Mac client" AUTO
D ENABLE_WEB OFF          # "Build Web client" OFF
D ENABLE_UTILS ON         # "Build utils (create, edit, show)" ON
D ENABLE_CLI ON           # "Build command-line client" OFF
D ENABLE_TESTS OFF        # "Build unit tests" ON
D ENABLE_LIGHTWEIGHT OFF  # "Optimize libtransmission for low-resource systems: smaller cache size, prefer unencrypted peer connections, etc." OFF
D ENABLE_UTP ON           # "Build µTP support" ON
D ENABLE_NLS ON           # "Enable native language support" ON
D INSTALL_DOC OFF         # "Build/install documentation" ON
D INSTALL_LIB OFF         # "Install the library" OFF
D RUN_CLANG_TIDY OFF      # "Run clang-tidy on the code" AUTO
D USE_SYSTEM_EVENT2 ON    # "Use system event2 library" AUTO
D USE_SYSTEM_DEFLATE ON   # "Use system deflate library" AUTO
D USE_SYSTEM_DHT OFF      # "Use system dht library" AUTO
D USE_SYSTEM_MINIUPNPC ON # "Use system miniupnpc library" AUTO
D USE_SYSTEM_NATPMP ON    # "Use system natpmp library" AUTO
D USE_SYSTEM_UTP OFF      # "Use system utp library" AUTO
D USE_SYSTEM_B64 ON       # "Use system b64 library" AUTO
D USE_SYSTEM_PSL ON       # "Use system psl library" AUTO
D WITH_CRYPTO openssl     # "Use specified crypto library" AUTO openssl cyassl polarssl ccrypto
D WITH_INOTIFY ON         # "Enable inotify support (on systems that support it)" AUTO
D WITH_KQUEUE OFF         # "Enable kqueue support (on systems that support it)" AUTO
D WITH_SYSTEMD OFF        # "Add support for systemd startup notification (on systems that support it)" AUTO

DIST_DIT=/tmp/build

x cmake \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	"${DEFINES[@]}" \
	-S. "-B$DIST_DIT"
x cmake --build "$DIST_DIT"
x cmake --install "$DIST_DIT" --prefix /opt/dist
