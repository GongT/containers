#!/usr/bin/env bash

set -Eeuo pipefail

python -m pip install --no-input --upgrade homeassistant

hass --help || true

hass --verbose | tee >/tmp/install.log &

while ! grep -qF '[homeassistant.core] Starting Home Assistant' /tmp/install.log; do
	sleep 5
done

echo "found complete signal!"
