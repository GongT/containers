for i in conf.d vhost.d stream.d rtmp.d; do
	if ! [[ -e "/config/$i" ]]; then
		echo "create /config/$i folder..." >&2
		mkdir -p "/config/$i"
	fi
done

if [[ -e "/config/htpasswd" ]]; then
	rm -f "/config/htpasswd"
fi
echo "create htpassword file..." >&2
htpasswd -bc "/config/htpasswd" "$USERNAME" "$PASSWORD"
