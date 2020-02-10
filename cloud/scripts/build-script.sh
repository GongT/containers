#!/bin/sh

set -e

apk --no-cache add nginx redis nextcloud \
	php-fpm php7-pdo_mysql php7-pecl-apcu php7-exif php7-opcache php7-pecl-imagick \
	nextcloud-activity \
	nextcloud-admin_audit \
	nextcloud-files_external \
	nextcloud-files_pdfviewer \
	nextcloud-files_trashbin \
	nextcloud-files_rightclick \
	nextcloud-files_sharing \
	nextcloud-files_versions \
	nextcloud-logreader \
	nextcloud-serverinfo \
	nextcloud-sharebymail \
	nextcloud-theming \
	nextcloud-text \
	nextcloud-cloud_federation_api \
	nextcloud-federation \
	nextcloud-viewer

mkdir -p /var/lib/nginx/logs /run/nginx

deluser nextcloud || true
adduser -h /var/lib/nextcloud -s /sbin/nologin -G users -D -H -u 100 media_rw || true

if [[ -L /usr/share/webapps/nextcloud/config ]]; then
	rm -f /usr/share/webapps/nextcloud/config
else
	rm -rf /usr/share/webapps/nextcloud/config
fi
mkdir -p /usr/share/webapps/nextcloud/config

AA='"$@"'
echo "#!/bin/sh
cd /usr/share/webapps/nextcloud
su -s /bin/sh media_rw -c 'php -d memory_limit=2G occ $AA' -- -- $AA
" > /usr/bin/occ
chmod a+x /usr/bin/occ

echo '<?php echo phpinfo();
' >/usr/share/webapps/nextcloud/updater/phpinfo.php
