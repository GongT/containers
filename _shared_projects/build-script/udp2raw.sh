function build_udp2raw() {
	local WORK=$(create_if_not build_udp2raw_worker gongt/alpine-cn)
	buildah run $WORK apk --no-cache add make gcc musl-dev g++ linux-headers

	buildah unmount $WORK
	local MNT_WORK=$(buildah mount $WORK)

	buildah copy $WORK "$_SHARED_PROJECTS_ROOT/wangyu-/udp2raw-tunnel/" /builds/udp2raw

	local GIT_VER=$(cd "$_SHARED_PROJECTS_ROOT/wangyu-/udp2raw-tunnel" && git rev-parse HEAD)
	echo "#!/bin/sh
	echo $GIT_VER
	" >"$MNT_WORK/builds/udp2raw/git"
	chmod a+x "$MNT_WORK/builds/udp2raw/git"

	buildah run $WORK sh -c 'export PATH="/builds/udp2raw:$PATH" && cd /builds/udp2raw && make -j'

	echo "${MNT_WORK}/builds/udp2raw/udp2raw"
	commit_shared "${MNT_WORK}/builds/udp2raw/udp2raw"
}
