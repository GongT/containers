#!/usr/bin/env bash

set -Eeuo pipefail

exec /usr/bin/dotnet /app/BililiveRecorder.Cli.dll run --bind "http://localhost:2356" /data
