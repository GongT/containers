#!/bin/bash

rm -f /run/sockets/next-cloud.sock

exec nginx
