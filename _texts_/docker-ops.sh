## base
# export to local:
buildah push localhost/gongt/nginx oci-archive:/tmp/images/nginx.oci:gongt/nginx:latest
# copy to remote
rsync -h --progress /tmp/images/nginx.oci wg-services:/data/temp-images/nginx.oci
# import to local
buildah rmi gongt/nginx ; buildah pull oci-archive:/data/temp-images/nginx.oci


## normal
# login
buildah login docker-registry.service.gongt.me
# /etc/containers/registries.conf is required to edit ( add to insecure registry )
buildah push localhost/gongt/nginx docker://docker-registry.service.gongt.me/gongt/nginx:latest

