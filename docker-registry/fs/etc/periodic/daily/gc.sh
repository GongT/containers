#!/bin/sh

registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
