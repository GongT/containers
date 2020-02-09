#!/bin/bash

rm -f /run/sockets/php-my-admin.sock

exec nginx
