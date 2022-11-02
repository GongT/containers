#!/bin/sh


exec /usr/sbin/php-fpm81 --nodaemonize --force-stderr --allow-to-run-as-root
