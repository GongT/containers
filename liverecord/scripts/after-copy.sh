set -Eeuo pipefail

# chattr +i /opt/app /opt/app/bin
# for I in /opt/app/bin/*/; do
# 	chattr +i "$I"
# done

chmod a+x /opt/app/bin/Server

ensure_group users 100
ensure_user media_rw 100 100
