#!/bin/bash

rm -f /run/sockets/word-press.sock

exec nginx
