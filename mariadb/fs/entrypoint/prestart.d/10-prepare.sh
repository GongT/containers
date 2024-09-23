mkdir -p /var/log/nginx /var/log/php-fpm /var/lib/nginx/logs
chmod 0777 /var/log/nginx /var/log/php-fpm
chmod -R 0777 /var/log/mariadb || true
