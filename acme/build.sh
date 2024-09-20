#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖项目
STEP="安装系统依赖"
buildah_cache_start "registry.fedoraproject.org/fedora-minimal"
dnf_use_environment
dnf_install_step "acme" scripts/deps.lst
### 依赖项目 END

### 安装acme
STEP="安装acme.sh"
REPO="acmesh-official/acme.sh"
BRANCH=master
hash_acme() {
	http_get_github_last_commit_id_on_branch "$REPO" "$BRANCH"
	cat scripts/build-acme.sh
}
do_acme() {
	local MNT
	MNT=$(create_temp_dir "acme.install.source")

	download_github "$REPO" "$BRANCH"
	download_git_result_copy "$MNT" "$REPO" "$BRANCH"

	buildah run "--volume=$MNT:/mnt" \
		"--volume=$(pwd)/scripts/build-acme.sh:/_tmp/script.sh:ro" \
		"$1" bash /_tmp/script.sh

	local NEW_VER=$(buildah run "$1" /opt/acme.sh/acme.sh --version 2>&1 | sed -E 's/^/> /g')
	control_ci summary "
${NEW_VER}

"
}
buildah_cache "acme" hash_acme do_acme
### 安装acme END

### 复制文件
STEP="复制文件"
merge_local_fs "acme"
### 安装acme END

STEP="配置镜像信息"
buildah_config "acme" \
	"--entrypoint=$(json_array /opt/entrypoint.sh)" \
	--stop-signal=SIGINT \
	--volume /opt/data --volume /etc/ACME \
	"--label=${LABELID_USE_NGINX_ATTACH}=yes"
info "settings updated..."

buildah_finalize_image "acme" gongt/acme
info "Done!"
