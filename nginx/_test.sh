set -e

bash ./build.sh
buildah push gongt/nginx oci-archive:/tmp/nginx:gongt/nginx:latest
scp /tmp/nginx services.gongt.me:/tmp/nginx.img
