UNAME=${USER_NAME:-}
UID=${USER_ID:-}
GID=${GROUP_ID:-}

unset USER_NAME USER_ID GROUP_ID

system_ensure_group "$GID" users
system_ensure_user "$UID" "$UNAME" "$GID"

unset UNAME UID GID
