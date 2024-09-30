set -Eeuo pipefail

# chattr +i /opt/app /opt/app/bin
# for I in /opt/app/bin/*/; do
# 	chattr +i "$I"
# done

chmod a+x /opt/app/bin/Server

ensure_group 100 users
ensure_user 100 media_rw 100
