#!/bin/sh


exec /usr/sbin/php-fpm7 --nodaemonize --force-stderr --allow-to-run-as-root
